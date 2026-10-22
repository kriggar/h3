#!/usr/bin/env python3
"""Capture a native scripted Mara motion review and encode a compact MP4."""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import select
import shutil
import subprocess
import tempfile
import time


def summarize_samples(report):
    """Expose measured evidence without treating toe-roll proxies as verdicts."""
    segments = {}
    for sample in report.get('samples', []):
        segment = segments.setdefault(sample['segment'], {
            'frames': 0, 'clips': [], 'maximum_bone_step_degrees': 0.0,
            'maximum_render_overwrite_degrees': 0.0, 'finite': True,
            'airborne_frames': 0, 'maximum_hit_weight': 0.0,
        })
        segment['frames'] += 1
        if sample['clip'] not in segment['clips']:
            segment['clips'].append(sample['clip'])
        segment['maximum_bone_step_degrees'] = max(segment['maximum_bone_step_degrees'],
            math.degrees(sample.get('largest_bone_step_radians', 0.0)))
        segment['maximum_render_overwrite_degrees'] = max(segment['maximum_render_overwrite_degrees'],
            math.degrees(sample.get('render_pose_overwrite_radians', 0.0)))
        segment['finite'] = segment['finite'] and sample.get('finite', False)
        segment['airborne_frames'] += int(not sample['grounded'])
        segment['maximum_hit_weight'] = max(segment['maximum_hit_weight'],
            sample.get('diagnostics', {}).get('hit_weight', 0.0))
    return {
        'segments': segments,
        'qualification': 'Scripted native presentation only. Bone-step maxima include purposeful action changes; '
                         'pose continuity and contact quality still require viewing the motion. '
                         'Authoritative combat and packet behavior are tested separately.',
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', required=True)
    parser.add_argument('--output-dir', required=True)
    parser.add_argument('--xvfb')
    parser.add_argument('--xvfb-lib-path')
    parser.add_argument('--avatar-script', default='res://game/online/avatar.gd')
    parser.add_argument('--label', default='Current animation controller')
    parser.add_argument('--metrics-only', action='store_true')
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    avatar_path = project/args.avatar_script.removeprefix('res://') if args.avatar_script.startswith('res://') else Path(args.avatar_script)
    source_paths = {'harness': project/'tests/online/animation_review.gd', 'avatar': avatar_path,
                    'catalog': project/'game/online/catalog.gd'}
    avatar_text = avatar_path.read_text()
    for name, resource in [('foot_placement', 'game/online/foot_placement.gd'),
                           ('extended_library', 'assets/online/animations/mara_extended.tres')]:
        if resource in avatar_text:
            source_paths[name] = project/resource
    source_hashes = {name:hashlib.sha256(path.read_bytes()).hexdigest() for name, path in source_paths.items()}
    isolation = Path(tempfile.mkdtemp(prefix='draconia-motion-review-'))
    env = os.environ.copy()
    env.update(XDG_DATA_HOME=str(isolation/'data'), XDG_CONFIG_HOME=str(isolation/'config'),
               XDG_CACHE_HOME=str(isolation/'cache'), LIBGL_ALWAYS_SOFTWARE='1', GALLIUM_DRIVER='llvmpipe')
    if args.xvfb_lib_path:
        env['LD_LIBRARY_PATH'] = args.xvfb_lib_path
    display_process = None
    xlog = None
    try:
        if args.xvfb and not args.metrics_only:
            read_fd, write_fd = os.pipe()
            xlog = (output/'xvfb.log').open('w')
            display_process = subprocess.Popen([args.xvfb, '-displayfd', str(write_fd), '-screen', '0',
                '1280x900x24', '-nolisten', 'tcp'], env=env, pass_fds=(write_fd,), stdout=xlog, stderr=subprocess.STDOUT)
            os.close(write_fd)
            try:
                ready, _, _ = select.select([read_fd], [], [], 15)
                if not ready:
                    raise RuntimeError('Xvfb did not announce a display')
                display = os.read(read_fd, 64).decode().strip()
            finally:
                os.close(read_fd)
            if not display.isdecimal():
                raise RuntimeError('Xvfb startup failed')
            env['DISPLAY'] = ':' + display
        command = [args.godot, '--path', str(project), '--audio-driver', 'Dummy', '--resolution', '960x720',
                   '--script', 'res://tests/online/animation_review.gd']
        if args.metrics_only:
            command += ['--headless']
        else:
            command += ['--rendering-method', 'gl_compatibility']
        command += ['--', '--output-dir=' + str(output), '--avatar-script=' + args.avatar_script, '--label=' + args.label]
        if args.metrics_only:
            command += ['--metrics-only']
        start = time.monotonic()
        with (output/'godot.log').open('w') as log:
            run = subprocess.run(command, cwd=project, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=240)
        text = (output/'godot.log').read_text()
        errors = [line for line in text.splitlines() if re.search(r'SCRIPT ERROR|^ERROR:|leaked|still in use|GL_INVALID', line)]
        evidence = output/'animation-review.json'
        report = json.loads(evidence.read_text()) if evidence.exists() else {}
        report['summary'] = summarize_samples(report)
        final_hashes = {name:hashlib.sha256(path.read_bytes()).hexdigest() for name, path in source_paths.items()}
        report['source_receipt'] = {'sha256_at_launch':source_hashes, 'unchanged_during_capture':source_hashes==final_hashes}
        if source_hashes != final_hashes:
            errors.append('Source files changed during capture; repeat before publishing this evidence')
        report['native_run'] = {'exit_code':run.returncode, 'seconds':round(time.monotonic()-start, 2), 'errors':errors,
            'rendering':'headless metrics' if args.metrics_only else 'native GL Compatibility under llvmpipe'}
        if run.returncode == 0 and not errors and report.get('captured'):
            movie = output/'animation-review.mp4'
            encode = subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-framerate', str(report['fps']),
                '-i', str(output/'frames/%05d.jpg'), '-c:v', 'libx264', '-crf', '21', '-preset', 'fast', '-pix_fmt', 'yuv420p',
                '-movflags', '+faststart', str(movie)], capture_output=True, text=True)
            if encode.returncode != 0:
                errors.append('Video encoding failed: ' + encode.stderr)
            else:
                report['video'] = {'file':movie.name, 'bytes':movie.stat().st_size, 'sha256':hashlib.sha256(movie.read_bytes()).hexdigest()}
                shutil.rmtree(output/'frames')
        if report:
            evidence.write_text(json.dumps(report, indent=2) + '\n')
        summary = {'exit_code':run.returncode, 'frames':report.get('frames',0), 'errors':errors,
                   'report':str(evidence), 'video':report.get('video')}
        print(json.dumps(summary, indent=2))
        return 0 if run.returncode == 0 and not errors and report.get('frames',0) > 0 else 1
    finally:
        if display_process is not None:
            display_process.terminate()
            try:
                display_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                display_process.kill()
                display_process.wait()
        if xlog:
            xlog.close()


if __name__ == '__main__':
    raise SystemExit(main())
