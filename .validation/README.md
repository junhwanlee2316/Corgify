# Validation photos

Public-domain portraits from Wikimedia Commons, used to check `FaceAnalyzer`
against real Vision landmark output:

    swift run corgify-analyze .validation/*.jpg

The tool prints each measurement, the resulting prompt, and an observed-vs-
configured range table that flags any feature whose real-world spread falls
outside `CorgiFaceMapper.HumanRange` (status `CLIPS`).

These images are not redistributed as part of the package build; fetch them
with `scripts/fetch-validation-photos.sh`.
