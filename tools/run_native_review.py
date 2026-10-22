#!/usr/bin/env python3
"""Run a real rendered Godot acceptance scene with isolated test saves.

Use an existing DISPLAY, or supply --xvfb. This never controls another app.
Godot captures its own rendered viewport; these are not concept mockups.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import select
import subprocess
import tempfile
import time


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--godot',required=True)
    parser.add_argument('--output-dir',required=True)
    parser.add_argument('--script',default='res://tests/online/acceptance.gd')
    parser.add_argument('--xvfb')
    parser.add_argument('--xvfb-lib-path')
    args=parser.parse_args()
    project=Path(__file__).resolve().parents[1]
    output=Path(args.output_dir).resolve();output.mkdir(parents=True,exist_ok=True)
    isolation=Path(tempfile.mkdtemp(prefix='draconia-native-review-'))
    env=os.environ.copy()
    env.update(XDG_DATA_HOME=str(isolation/'data'),XDG_CONFIG_HOME=str(isolation/'config'),
               XDG_CACHE_HOME=str(isolation/'cache'),LIBGL_ALWAYS_SOFTWARE='1',GALLIUM_DRIVER='llvmpipe')
    display_process=None
    xlog=None
    if args.xvfb_lib_path:env['LD_LIBRARY_PATH']=args.xvfb_lib_path
    try:
        if args.xvfb:
            read_fd,write_fd=os.pipe()
            xlog=(output/'xvfb.log').open('w')
            display_process=subprocess.Popen([args.xvfb,'-displayfd',str(write_fd),'-screen','0','1920x1080x24','-nolisten','tcp'],
                env=env,pass_fds=(write_fd,),stdout=xlog,stderr=subprocess.STDOUT)
            os.close(write_fd)
            try:
                ready,_,_=select.select([read_fd],[],[],15)
                if not ready:raise RuntimeError('Xvfb did not announce a display')
                display=os.read(read_fd,64).decode().strip()
            finally:os.close(read_fd)
            if not display.isdecimal():raise RuntimeError('Xvfb startup failed')
            env['DISPLAY']=':'+display
        started=time.monotonic()
        with (output/'godot.log').open('w') as log:
            run=subprocess.run([args.godot,'--path',str(project),'--rendering-method','gl_compatibility',
                '--audio-driver','Dummy','--resolution','1440x900','--script',args.script,'--',
                '--output-dir='+str(output)],cwd=project,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=300)
        text=(output/'godot.log').read_text()
        errors=[line for line in text.splitlines() if re.search(r'SCRIPT ERROR|^ERROR:|leaked|still in use|GL_INVALID',line)]
        evidence_path=output/'acceptance.json'
        evidence=json.loads(evidence_path.read_text()) if evidence_path.exists() else {}
        captures=[{'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
                  for p in sorted(output.glob('*.png'))]
        result={'exit_code':run.returncode,'seconds':round(time.monotonic()-started,2),'runtime_errors':errors,
                'passed':run.returncode==0 and not errors and evidence.get('passed',False),
                'checks':evidence.get('checks',0),'captures':captures,
                'method':'Native Godot GL Compatibility / llvmpipe; scripted engine inputs and own-viewport captures.',
                'limits':'This is not a hardware GPU benchmark or a manual long-duration playtest.'}
        (output/'native-report.json').write_text(json.dumps(result,indent=2)+'\n')
        print(json.dumps(result,indent=2))
        return 0 if result['passed'] else 1
    finally:
        if display_process is not None:
            display_process.terminate()
            try:display_process.wait(timeout=5)
            except subprocess.TimeoutExpired:display_process.kill();display_process.wait()
        if xlog:xlog.close()


if __name__=='__main__':raise SystemExit(main())
