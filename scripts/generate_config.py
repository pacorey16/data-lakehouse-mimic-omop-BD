#!/usr/bin/env python3
"""
Genera los ficheros de configuración de Trino a partir de los templates
y las credenciales definidas en .env.

Uso: python3 scripts/generate_config.py
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent


def load_env(env_path: Path) -> dict:
    env = {}
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1)
            env[k.strip()] = v.strip()
    return env


def generate(template_path: Path, output_path: Path, env: dict) -> None:
    content = template_path.read_text()
    content = re.sub(
        r'\$\{(\w+)\}',
        lambda m: env.get(m.group(1), m.group(0)),
        content
    )
    output_path.write_text(content)
    print(f"  OK  {output_path.relative_to(ROOT)}")


TEMPLATES = [
    ('docker/trino/conf/catalog/iceberg.properties.template',
     'docker/trino/conf/catalog/iceberg.properties'),
    ('docker/trino/conf/catalog/hive.properties.template',
     'docker/trino/conf/catalog/hive.properties'),
    ('docker/trino/conf/core-site.xml.template',
     'docker/trino/conf/core-site.xml'),
]

if __name__ == '__main__':
    env_path = os.environ.get('ENV_FILE', 'docker/.env')
    env_file = ROOT / env_path
    if not env_file.exists():
        print(f"ERROR: No existe {env_file}. Ejecuta 'make env' primero.")
        sys.exit(1)

    env = load_env(env_file)
    missing = [k for k in ('MINIO_ROOT_USER', 'MINIO_ROOT_PASSWORD') if not env.get(k)]
    if missing:
        print(f"ERROR: Faltan en .env: {', '.join(missing)}")
        sys.exit(1)

    print("Generando configuraciones de Trino...")
    for template_rel, output_rel in TEMPLATES:
        generate(ROOT / template_rel, ROOT / output_rel, env)
    print("Listo.")
