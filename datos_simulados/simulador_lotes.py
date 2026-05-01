"""
Trocea los CSV de MIMIC en lotes anuales simulando llegada incremental de datos.

Salida: datos_simulados/lotes_landing/YYYY/<tabla>.csv
- admissions    → particionado por año de admittime
- diagnoses_icd → hereda el año de admittime via hadm_id
- patients      → aparece en el año de su primera admisión
"""

import pandas as pd
from pathlib import Path

DATA_DIR = Path(__file__).parent.parent / "data"
OUTPUT_DIR = Path(__file__).parent / "lotes_landing"


def save_partition(df: pd.DataFrame, anio: str, table_name: str) -> None:
    folder = OUTPUT_DIR / anio
    folder.mkdir(parents=True, exist_ok=True)
    df.to_csv(folder / f"{table_name}.csv", index=False)


def procesar_admissions(df: pd.DataFrame) -> pd.Series:
    """Devuelve Series hadm_id -> año (str) y particiona admissions."""
    df["_anio"] = pd.to_datetime(df["admittime"]).dt.year.astype(str)
    for anio, group in df.groupby("_anio"):
        save_partition(group.drop(columns=["_anio"]), anio, "admissions")
    return df.set_index("hadm_id")["_anio"]


def procesar_diagnoses_icd(df: pd.DataFrame, anio_por_hadm: pd.Series) -> None:
    df["_anio"] = df["hadm_id"].map(anio_por_hadm)
    sin_anio = df["_anio"].isna().sum()
    if sin_anio:
        print(f"  [aviso] {sin_anio} filas de diagnoses_icd sin hadm_id conocido — se omiten")
    df = df.dropna(subset=["_anio"])
    for anio, group in df.groupby("_anio"):
        save_partition(group.drop(columns=["_anio"]), anio, "diagnoses_icd")


def procesar_patients(patients: pd.DataFrame, admissions: pd.DataFrame) -> None:
    """Cada paciente aparece en el año de su primera admisión."""
    primera_admision = (
        pd.to_datetime(admissions["admittime"])
        .groupby(admissions["subject_id"])
        .min()
        .dt.year.astype(str)
        .rename("_anio")
    )
    df = patients.join(primera_admision, on="subject_id")
    sin_anio = df["_anio"].isna().sum()
    if sin_anio:
        print(f"  [aviso] {sin_anio} pacientes sin admisión conocida — se omiten")
    df = df.dropna(subset=["_anio"])
    for anio, group in df.groupby("_anio"):
        save_partition(group.drop(columns=["_anio"]), anio, "patients")


def main() -> None:
    print("Cargando CSVs...")
    admissions = pd.read_csv(DATA_DIR / "admissions.csv")
    diagnoses = pd.read_csv(DATA_DIR / "diagnoses_icd.csv")
    patients = pd.read_csv(DATA_DIR / "patients.csv")

    print("Procesando admissions...")
    fecha_por_hadm = procesar_admissions(admissions)

    print("Procesando diagnoses_icd...")
    procesar_diagnoses_icd(diagnoses, fecha_por_hadm)

    print("Procesando patients...")
    procesar_patients(patients, admissions)

    lotes = sorted(OUTPUT_DIR.iterdir())
    print(f"\nListo. {len(lotes)} lotes generados en {OUTPUT_DIR}")
    for lote in lotes:
        archivos = [f.name for f in lote.iterdir()]
        print(f"  {lote.name}: {archivos}")


if __name__ == "__main__":
    main()
