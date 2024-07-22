from pyinfra import host
from pyinfra.facts.server import LinuxName, Home, KernelVersion
from pyinfra.operations import apt, zypper, files, python, systemd

import utils


if host.get_fact(KernelVersion).count('microsoft') == 0:
    systemd.service(
        name='Enable ssh-agent user service',
        service='ssh-agent.service',
        user_mode=True,
        enabled=True,
    )

FONTS_DIR = f'{host.get_fact(Home)}/.local/share/fonts'
FONTS_ARCHIVES_DIR = f'{FONTS_DIR}/archives'

files.directory(
    name='Create font archives directory',
    path=FONTS_ARCHIVES_DIR,
)


for font_name in ['Hack.tar.xz', 'RobotoMono.tar.xz']:
    font = utils.NerdFont(font_name, 'v3.2.1')
    font_file = f'{FONTS_ARCHIVES_DIR}/{font.basename}'
    fonts_downloaded = files.download(
        name=f'Download font {font_name}',
        src=font.url,
        dest=font_file,
        sha256sum=font.sha256,
    )

    python.call(
        name=f'Extract font {font_name}',
        function=utils.extract_tarfile,
        file=font_file,
        dest=FONTS_DIR,
        exclude=['LICENSE.*', 'README.md'],
    )


if host.get_fact(LinuxName) == 'openSUSE Tumbleweed':
    zypper.packages(
        name='Install required packages',
        packages=[
            'btop',
            'gdu',
            'git',
            'gping',
            'k9s',
            'lf',
            'tmux',
            'yq',
        ],
        _sudo=True,
    )

    files.line(
        name='Use .bash_aliases',
        path=f'{host.get_fact(Home)}/.bashrc',
        line=r'test -s ~/.alias && . ~/.alias || true',
        replace=r'test -s ~/.bash_aliases && . ~/.bash_aliases || true',
    )


if host.get_fact(LinuxName) == 'Ubuntu':
    apt.packages(
        name='Install required packages',
        packages=[
            'btop',
            'gdu',
            'git',
            'tmux',
        ],
        _sudo=True,
    )
