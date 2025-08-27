import glob
import os

from pyinfra.context import host
from pyinfra.facts.server import LinuxName, Home, KernelVersion
from pyinfra.operations import apt, zypper, files, python, systemd

import utils

HOME_DIR = host.get_fact(Home)

if host.get_fact(KernelVersion).count('microsoft') == 0:
    files.put(
        name='Add ssh-agent user service',
        src='files/systemd/ssh-agent.service',
        dest=f'{HOME_DIR}/.config/systemd/user/ssh-agent.service',
        create_remote_dir=True,
    )
    systemd.service(
        name='Enable ssh-agent user service',
        service='ssh-agent.service',
        user_mode=True,
        enabled=True,
    )
else:
    files.put(
        name='WSL configuration',
        src='files/wsl.conf',
        dest='/etc/wsl.conf',
        _sudo=True,
    )


FONTS_DIR = f'{HOME_DIR}/.local/share/fonts'
FONTS_ARCHIVES_DIR = f'{FONTS_DIR}/archives'
NERD_FONTS = {
    'version': 'v3.2.1',
    'fonts': ['Hack.tar.xz', 'RobotoMono.tar.xz'],
}


files.directory(
    name='Create font archives directory',
    path=FONTS_ARCHIVES_DIR,
)


for font_name in NERD_FONTS['fonts']:
    font = utils.NerdFont(font_name, NERD_FONTS['version'])
    font_file = f'{FONTS_ARCHIVES_DIR}/{font_name}'
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

for completion in glob.glob('files/bash_completion/*'):
    base_name = os.path.basename(completion)
    files.put(
        name=f'Add bash completion {base_name}',
        src=completion,
        dest=f'{HOME_DIR}/.local/share/bash_completion.d/{base_name}',
        create_remote_dir=True,
    )

for script in glob.glob('files/scripts/*'):
    base_name = os.path.basename(script)
    files.put(
        name=f'Add custom script {base_name}',
        src=script,
        dest=f'{HOME_DIR}/.local/bin/{base_name}',
        create_remote_dir=True,
        mode='755',
    )


if host.get_fact(LinuxName) == 'openSUSE Tumbleweed':
    zypper.packages(
        name='Install required packages',
        packages=[
            'btop',
            'chezmoi-bash-completion',
            'fetchmsttfonts',
            'gdu',
            'git',
            'gping',
            'helm',
            'helm-bash-completion',
            'k9s',
            'keepassxc',
            'lf',
            'mtr',
            'ShellCheck',
            'socat',
            'timg',
            'tmux',
            'yq',
        ],
        _sudo=True,
    )

    files.line(
        name='Use .bash_aliases instead of .alias',  # type: ignore
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
            'mtr',
            'shellcheck',
            'socat',
            'tmux',
            'unzip',
        ],
        _sudo=True,
    )


files.put(
    name='Lower the default metric value for the Network Manager',
    src='files/default-route-metric.conf',
    dest='/etc/NetworkManager/conf.d/',
    _sudo=True,
)

files.block(
    name='Adjust system buffer size to 1% of total memory',
    path='/etc/sysctl.conf',
    content="""
vm.dirty_bytes = 200000000
vm.dirty_background_bytes = 100000000
""",
    _sudo=True,
)
