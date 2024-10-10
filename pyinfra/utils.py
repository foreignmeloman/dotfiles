import fnmatch
import os
import tarfile
import urllib.request


def _exclude_tarfile_members(tar_archive: tarfile.TarFile, exclude: list):
    excluded_members = [
        f for e in exclude for f in fnmatch.filter(tar_archive.getnames(), e)
    ]
    for tarinfo in tar_archive:
        if tarinfo.name not in excluded_members:
            yield tarinfo


def extract_tarfile(file: str, dest: str, exclude: list):
    if tarfile.is_tarfile(file):
        with tarfile.open(file) as fh:
            fh.extractall(
                path=dest,
                members=_exclude_tarfile_members(fh, exclude),
            )
    else:
        raise Exception(f'{file} is not a tar archive!')


class NerdFont:
    BASE_URL = 'https://github.com/ryanoasis/nerd-fonts/releases/download'

    def __init__(self, name: str, version: str) -> None:
        self.__name = name
        self.__version = version

    @property
    def sha256(self) -> str:
        sha256_url = f'{self.BASE_URL}/{self.__version}/SHA-256.txt'
        sha256_file = f'/tmp/NF-SHA256-{self.__version}.txt'
        if os.path.isfile(sha256_file):
            with open(sha256_file, 'r') as fh:
                data = fh.read()
        else:
            with urllib.request.urlopen(sha256_url) as response:
                data = response.read().decode().strip()
                with open(sha256_file, 'w') as fh:
                    fh.write(data)
        data_parsed = [line.split() for line in data.split('\n')]
        return list(
            filter(
                lambda x: x[1] == self.__name,
                data_parsed,
            )
        )[0][0]

    @property
    def url(self) -> str:
        return f'{self.BASE_URL}/{self.__version}/{self.__name}'
