#!/usr/bin/env python3
"""Build a textured Mara candidate without resampling the accepted rig.

All existing binary accessor data, nodes, skin matrices and animation channels
are preserved byte for byte. Only material descriptions, shared image links,
and previously missing weapon/cowl UV attributes are added. Two deliberately
repaired costume/body meshes are merged from Blender while retaining the
original skin and all animation data. Blender also authors the detail maps.
"""
from __future__ import annotations
import copy
import hashlib
import json
import math
import shutil
import struct
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/models/source/characters"
SOURCE_MAPS = SOURCE / "pbr-sources"
PREPARED = SOURCE / "mara-pbr-v9/prepared"
BAKES = SOURCE / "mara-pbr-v9/bakes"
STAGE = ROOT / "assets/staging/mara-pbr-v9"
CANDIDATE = STAGE / "candidate"
BASE = ROOT / "assets/models/mara"
FILES = ("mara.glb", "sword.glb", "equipment/vowkeeper.glb", "equipment/bellworn-cowl.glb")
COMPONENTS = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<III", data)
    assert magic == 0x46546C67 and version == 2 and length == len(data)
    count, kind = struct.unpack_from("<II", data, 12)
    assert kind == 0x4E4F534A
    document = json.loads(data[20:20 + count])
    size, kind = struct.unpack_from("<II", data, 20 + count)
    assert kind == 0x004E4942
    return document, data[28 + count:28 + count + size]


def accessor(document: dict, binary: bytes, index: int) -> np.ndarray:
    record = document["accessors"][index]
    view = document["bufferViews"][record["bufferView"]]
    dtype = np.dtype(COMPONENTS[record["componentType"]]).newbyteorder("<")
    width = WIDTHS[record["type"]]
    offset = view.get("byteOffset", 0) + record.get("byteOffset", 0)
    stride = view.get("byteStride", width * dtype.itemsize)
    return np.ndarray((record["count"], width), dtype=dtype, buffer=binary, offset=offset,
                      strides=(stride, dtype.itemsize)).copy()


def material_metres_per_uv(document: dict, binary: bytes) -> dict[int, float]:
    areas: dict[int, list[float]] = {}
    for mesh in document["meshes"]:
        for primitive in mesh["primitives"]:
            if "TEXCOORD_0" not in primitive["attributes"]:
                continue
            position = accessor(document, binary, primitive["attributes"]["POSITION"])
            uv = accessor(document, binary, primitive["attributes"]["TEXCOORD_0"])
            indices = accessor(document, binary, primitive["indices"]).reshape(-1, 3)
            edges1, edges2 = position[indices[:, 1]] - position[indices[:, 0]], position[indices[:, 2]] - position[indices[:, 0]]
            uv1, uv2 = uv[indices[:, 1]] - uv[indices[:, 0]], uv[indices[:, 2]] - uv[indices[:, 0]]
            world_area = np.linalg.norm(np.cross(edges1, edges2), axis=1) * 0.5
            uv_area = np.abs(uv1[:, 0] * uv2[:, 1] - uv1[:, 1] * uv2[:, 0]) * 0.5
            valid = uv_area > 1e-12
            total = areas.setdefault(primitive["material"], [0.0, 0.0])
            total[0] += float(world_area[valid].sum())
            total[1] += float(uv_area[valid].sum())
    return {index: math.sqrt(a / b) for index, (a, b) in areas.items() if a > 0 and b > 0}


def merge_costume_meshes(document: dict, binary: bytearray) -> list[str]:
    source, source_binary = read_glb(SOURCE / "mara-pbr-v9/costume-seams.glb")
    target_names = {node.get("name"): node for node in document["nodes"]}
    target_materials = {material["name"]: index for index, material in enumerate(document["materials"])}
    source_joints = [source["nodes"][index]["name"] for index in source["skins"][0]["joints"]]
    target_joints = [document["nodes"][index]["name"] for index in document["skins"][0]["joints"]]
    assert source_joints == target_joints, "Mesh repair export changed joint binding order"
    assert np.allclose(accessor(source, source_binary, source["skins"][0]["inverseBindMatrices"]),
                       accessor(document, binary, document["skins"][0]["inverseBindMatrices"]), atol=1e-6), "Mesh repair bind pose differs"
    copied_views, copied_accessors = {}, {}

    def copy_accessor(index: int) -> int:
        if index not in copied_accessors:
            record = copy.deepcopy(source["accessors"][index])
            old_view = record["bufferView"]
            if old_view not in copied_views:
                view = copy.deepcopy(source["bufferViews"][old_view])
                start = view.get("byteOffset", 0)
                while len(binary) % 4:
                    binary.append(0)
                view["byteOffset"] = len(binary)
                view["buffer"] = 0
                binary.extend(source_binary[start:start + view["byteLength"]])
                copied_views[old_view] = len(document["bufferViews"])
                document["bufferViews"].append(view)
            record["bufferView"] = copied_views[old_view]
            copied_accessors[index] = len(document["accessors"])
            document["accessors"].append(record)
        return copied_accessors[index]

    repaired = []
    for node in source["nodes"]:
        if "mesh" not in node:
            continue
        assert node["name"] in ("Ileana.Body", "Ileana.WoolTunic")
        target_node = target_names[node["name"]]
        for field in ("matrix", "rotation", "scale", "translation"):
            assert node.get(field) == target_node.get(field), "Repaired mesh transform changed"
        mesh = copy.deepcopy(source["meshes"][node["mesh"]])
        mesh["name"] = document["meshes"][target_node["mesh"]]["name"]
        for primitive in mesh["primitives"]:
            primitive["attributes"] = {name: copy_accessor(index) for name, index in primitive["attributes"].items()}
            primitive["indices"] = copy_accessor(primitive["indices"])
            primitive["material"] = target_materials[source["materials"][primitive["material"]]["name"]]
        document["meshes"][target_node["mesh"]] = mesh
        repaired.append(node["name"])
    assert set(repaired) == {"Ileana.Body", "Ileana.WoolTunic"}
    return repaired


def missing_uvs(document: dict, binary: bytearray, units: dict[int, float]) -> int:
    count = 0
    original = bytes(binary)
    for mesh in document["meshes"]:
        primitives = [p for p in mesh["primitives"] if "TEXCOORD_0" not in p["attributes"]]
        if not primitives:
            continue
        all_points = np.unique(np.round(np.concatenate([accessor(document, original, p["attributes"]["POSITION"]) for p in mesh["primitives"]]), 6), axis=0)
        centre = all_points.mean(axis=0)
        _, _, axes = np.linalg.svd(all_points - centre, full_matrices=False)
        for axis in axes:
            if axis[np.argmax(np.abs(axis))] < 0:
                axis *= -1
        for primitive in primitives:
            points = accessor(document, original, primitive["attributes"]["POSITION"])
            if "Cowl" in mesh.get("name", ""):
                # Cylindrical cloth coordinates, in metres, with a back seam.
                angle = np.arctan2(points[:, 0], points[:, 2] - 0.025)
                uv = np.column_stack((angle * 0.13, -points[:, 1]))
            else:
                # Principal long-axis alignment keeps scratches/grain along
                # the physical blade/grip instead of changing with animation.
                uv = np.column_stack(((points - centre) @ axes[1], -((points - centre) @ axes[0])))
            uv = (uv / units.get(primitive["material"], 1.0)).astype("<f4")
            while len(binary) % 4:
                binary.append(0)
            view = len(document["bufferViews"])
            document["bufferViews"].append({"buffer": 0, "byteOffset": len(binary), "byteLength": uv.nbytes, "target": 34962})
            binary.extend(uv.tobytes())
            index = len(document["accessors"])
            document["accessors"].append({"bufferView": view, "componentType": 5126, "count": len(uv), "type": "VEC2"})
            primitive["attributes"]["TEXCOORD_0"] = index
            count += 1
    return count


def write_glb(path: Path, document: dict, binary: bytearray) -> None:
    document["buffers"][0]["byteLength"] = len(binary)
    while len(binary) % 4:
        binary.append(0)
    encoded = json.dumps(document, separators=(",", ":"), ensure_ascii=False).encode()
    encoded += b" " * ((-len(encoded)) % 4)
    data = struct.pack("<III", 0x46546C67, 2, 28 + len(encoded) + len(binary))
    data += struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
    data += struct.pack("<II", len(binary), 0x004E4942) + binary
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def main() -> None:
    shared = CANDIDATE / "materials"
    shared.mkdir(parents=True, exist_ok=True)
    originals = json.loads((SOURCE_MAPS / "manifest.json").read_text())
    dimension = {x["id"]: float(x["dimensionsMillimetres"][0]) / 1000.0 for x in originals["assets"]}
    dimension["metal012"] = 0.30  # Authored scale; source publishes no metre width.
    maps = {}
    for asset in ("caban", "rough_linen", "brown_leather"):
        base = PREPARED / (asset + "_neutral_albedo_2k.png") if asset != "brown_leather" else ROOT / next(x["path"] for x in originals["files"] if x["asset"] == asset and x["channel"] == "Diffuse")
        orm = ROOT / next(x["path"] for x in originals["files"] if x["asset"] == asset and x["channel"] == "arm")
        maps[asset] = {"albedo": base, "orm": orm, "normal": PREPARED / (asset + "_normal_gl.png")}
    maps["metal012"] = {"albedo": SOURCE_MAPS / "metal012/Metal012_1K-PNG_Color.png",
                        "orm": PREPARED / "metal012_orm_1k.png", "normal": PREPARED / "metal012_normal_gl.png"}
    maps["skin"] = {"orm": BAKES / "mara_skin_orm.png", "normal": BAKES / "mara_skin_micro_normal.png"}
    for surfaces in maps.values():
        for key, path in surfaces.items():
            assert path.is_file(), f"Missing prepared map: {path}"
            target = shared / path.name
            shutil.copy2(path, target)
            surfaces[key] = target

    # Each rule is a material recipe; scalar factors are linear, not sRGB.
    recipes = {
        "Draconia.MadderWool": ("caban", [0.25, 0.042, 0.029, 1], 0.0, 0.96, 0.55),
        "Draconia.UnbleachedLinen": ("rough_linen", [0.70, 0.59, 0.43, 1], 0.0, 1.0, 0.45),
        "Draconia.WarmLinen": ("rough_linen", [0.66, 0.51, 0.33, 1], 0.0, 1.0, 0.45),
        "Draconia.DarkLeather": ("brown_leather", [0.40, 0.29, 0.22, 1], 0.0, 0.98, 0.35),
        "Draconia.CopperFastener": ("metal012", [0.60, 0.32, 0.10, 1], 0.95, 0.90, 0.20),
        "Draconia.OchreWovenTrim": ("rough_linen", [0.46, 0.24, 0.072, 1], 0.0, 1.0, 0.40),
        "Draconia.WornIron": ("metal012", [0.68, 0.70, 0.71, 1], 0.95, 0.78, 0.18),
        "Vowkeeper.Steel": ("metal012", [0.75, 0.78, 0.81, 1], 0.98, 0.70, 0.16),
        "Vowkeeper.RecessedFuller": ("metal012", [0.24, 0.27, 0.28, 1], 0.92, 1.0, 0.20),
        "Vowkeeper.WornBronze": ("metal012", [0.66, 0.35, 0.11, 1], 0.95, 0.85, 0.20),
        "Vowkeeper.BoundLeather": ("brown_leather", [0.32, 0.23, 0.18, 1], 0.0, 0.98, 0.35),
        "Vowkeeper.WrapEdges": ("brown_leather", [0.55, 0.38, 0.25, 1], 0.0, 1.0, 0.35),
        "Bellworn.CharcoalBlueWool": ("caban", [0.052, 0.080, 0.11, 1], 0.0, 1.0, 0.50),
        "Bellworn.BrownWovenBinding": ("rough_linen", [0.16, 0.10, 0.055, 1], 0.0, 1.0, 0.40),
        "Bellworn.LinenLining": ("rough_linen", [0.48, 0.39, 0.25, 1], 0.0, 1.0, 0.35),
    }
    results = []
    for relative in FILES:
        backup = STAGE / "accepted-v8" / relative
        if not backup.exists():
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(BASE / relative, backup)
        original, payload = read_glb(backup)
        document, binary = copy.deepcopy(original), bytearray(payload)
        repaired_meshes = merge_costume_meshes(document, binary) if relative == "mara.glb" else []
        units = material_metres_per_uv(document, bytes(binary))
        new_uvs = missing_uvs(document, binary, units)
        textures = document.setdefault("textures", [])
        images = document.setdefault("images", [])
        samplers = document.setdefault("samplers", [])
        sampler = len(samplers)
        samplers.append({"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497})
        texture_indices = {}
        prefix = "../materials/" if relative.startswith("equipment/") else "materials/"

        def texture(path: Path) -> int:
            if path.name not in texture_indices:
                image_index = len(images)
                images.append({"uri": prefix + path.name, "name": path.stem,
                               "mimeType": "image/jpeg" if path.suffix.lower() in (".jpg", ".jpeg") else "image/png"})
                texture_indices[path.name] = len(textures)
                textures.append({"source": image_index, "sampler": sampler})
            return texture_indices[path.name]

        def reference(path: Path, scale: float = 1.0) -> dict:
            value = {"index": texture(path)}
            if abs(scale - 1.0) > 1e-7:
                value["extensions"] = {"KHR_texture_transform": {"scale": [scale, scale]}}
                extensions = document.setdefault("extensionsUsed", [])
                if "KHR_texture_transform" not in extensions:
                    extensions.append("KHR_texture_transform")
            return value

        material_notes = []
        for index, material in enumerate(document["materials"]):
            name = material["name"]
            if name in recipes:
                asset, tint, metallic, roughness, normal_strength = recipes[name]
                scale = units.get(index, 1.0) / dimension[asset]
                material["pbrMetallicRoughness"] = {"baseColorFactor": tint,
                    "baseColorTexture": reference(maps[asset]["albedo"], scale),
                    "metallicFactor": metallic, "roughnessFactor": roughness,
                    "metallicRoughnessTexture": reference(maps[asset]["orm"], scale)}
                material["normalTexture"] = reference(maps[asset]["normal"], scale) | {"scale": normal_strength}
                material["occlusionTexture"] = reference(maps[asset]["orm"], scale) | {"strength": 0.30}
                material["alphaMode"] = "OPAQUE"
                material_notes.append({"material": name, "sourceAsset": asset, "metresPerOriginalUvUnit": units.get(index, 1.0),
                                       "sourceWidthMetres": dimension[asset], "uvScale": scale, "normalStrength": normal_strength,
                                       "baseColorFactorLinear": tint, "roughnessFactor": roughness, "metallicFactor": metallic})
            elif name == "Ileana.Body.body":
                material["alphaMode"] = "OPAQUE"
                material["doubleSided"] = False
                material["pbrMetallicRoughness"]["roughnessFactor"] = 1.0
                material["pbrMetallicRoughness"]["metallicRoughnessTexture"] = reference(maps["skin"]["orm"])
                material["normalTexture"] = reference(maps["skin"]["normal"]) | {"scale": 0.65}
                material_notes.append({"material": name, "sourceAsset": "Existing CC0 MakeHuman albedo plus original Blender microdetail bake",
                                       "normalStrength": 0.65, "newSkinScan": False})
            elif name == "Ileana.high-poly":
                # The accepted eye mesh has a transparent corneal shell.
                # Making it opaque hides the iris behind that shell.
                material["alphaMode"] = original["materials"][index].get("alphaMode", "OPAQUE")
                material["pbrMetallicRoughness"]["roughnessFactor"] = 0.25
            elif name == "Ileana.rehmanpolanski_viking_boots":
                material["alphaMode"] = "OPAQUE"
                material["pbrMetallicRoughness"]["roughnessFactor"] = 0.73
            elif name in ("Ileana.braid01", "Ileana.eyebrow001", "Ileana.eyelashes01"):
                material["alphaMode"] = "MASK" if name == "Ileana.braid01" else "BLEND"
                if name == "Ileana.braid01":
                    material["alphaCutoff"] = 0.30
                material["pbrMetallicRoughness"]["roughnessFactor"] = 0.62 if name == "Ileana.braid01" else 0.72
        output = CANDIDATE / relative
        write_glb(output, document, binary)
        saved, saved_binary = read_glb(output)
        assert saved_binary[:len(payload)] == payload, "Accepted vertex/skin/animation binary changed"
        for key in ("nodes", "skins", "animations", "scenes", "scene"):
            assert saved.get(key) == original.get(key), f"Accepted {key} changed"
        for old_mesh, new_mesh in zip(original["meshes"], saved["meshes"]):
            if relative == "mara.glb" and old_mesh["name"] in ("base.001", "tunicviking.001"):
                continue
            for old_primitive, new_primitive in zip(old_mesh["primitives"], new_mesh["primitives"]):
                for attribute, value in old_primitive["attributes"].items():
                    assert new_primitive["attributes"][attribute] == value
        results.append({"file": relative, "previousSha256": hashlib.sha256(backup.read_bytes()).hexdigest(),
                        "candidateSha256": hashlib.sha256(output.read_bytes()).hexdigest(), "bytes": output.stat().st_size,
                        "acceptedBinaryPreserved": True, "nodesSkinsAnimationsPreserved": True,
                        "repairedMeshNodes": repaired_meshes,
                        "addedUvPrimitives": new_uvs, "materialRecipes": material_notes})
    report = {"version": "v9-pbr-candidate", "status": "Requires actual native appearance and animation review before promotion",
              "models": results, "textures": [{"file": "materials/" + p.name, "bytes": p.stat().st_size,
                                                  "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(shared.iterdir()) if p.is_file()],
              "nativeLimits": "PBR materials and two garment/neck mesh repairs; original skeleton/animation binary preserved. Static braid, LODs and remaining character-production gates are unfinished."}
    (STAGE / "candidate-manifest.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"models": len(results), "materialRecipes": sum(len(x["materialRecipes"]) for x in results),
                      "modelBytes": sum(x["bytes"] for x in results), "sharedTextureBytes": sum(x["bytes"] for x in report["textures"]),
                      "report": str(STAGE / "candidate-manifest.json")}))


if __name__ == "__main__":
    main()
