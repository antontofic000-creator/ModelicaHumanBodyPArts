within ModelicaHumanBodyPArts;
  package Types
    extends Modelica.Icons.TypesPackage;
  
    type Sex = enumeration(
      Female "Use the female coefficients of the selected source dataset",
      Male "Use the male coefficients of the selected source dataset",
      Mean "Arithmetic mean of female/male coefficients; computational convenience only")
      "Dataset selector; not a biological model";
  
    type SegmentKey = enumeration(
      Foot,
      Shank,
      Thigh,
      Pelvis)
      "Lower-body segment identifiers implemented in v0.2";
  
    type ProvenanceClass = enumeration(
      PublishedScientificSource "Published scientific source",
      NewProjectDerivation "New derivation made in this project",
      ExplicitModelAssumption "Explicit modelling assumption",
      CanonicalLynkorrExperiment "Information from a canonical Lynkorr experiment")
      "Required provenance class for important equations, parameters, assumptions and datasets";
  
    type ScalingLevel = enumeration(
      Level1GeometricSimilarity "Dimensional/geometric similarity baseline",
      Level2PopulationRegression "Population anthropometric regression",
      Level3SubjectSpecific "Subject-specific measurements or corrections")
      "Anthropometric scaling hierarchy used by the project";
  
    type ROMNature = enumeration(
      Unknown "Measurement type not specified",
      Active "Actively produced range of motion",
      Passive "Externally assisted/passive range of motion",
      Functional "Task-specific functional range rather than anatomical maximum")
      "Nature of a joint-mobility observation or parameter set";
  
  end Types;

