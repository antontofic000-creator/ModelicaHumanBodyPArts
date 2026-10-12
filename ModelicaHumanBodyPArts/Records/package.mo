within ModelicaHumanBodyPArts;
  package Records
    extends Modelica.Icons.RecordsPackage;
  
    record AnthropometryProfile
      "Subject-level data used by the lower-body scaling layer"
      import SI = Modelica.Units.SI;
    
      SI.Length height "Standing stature";
      SI.Mass mass "Whole-body mass";
      ModelicaHumanBodyPArts.Types.Sex sex;
      ModelicaHumanBodyPArts.Types.ScalingLevel scalingLevel =
        ModelicaHumanBodyPArts.Types.ScalingLevel.Level3SubjectSpecific
        "How the dimensional inputs in this profile were obtained";
    
      SI.Length footLength
        "Heel-to-toe foot length used by the current foot mass-property model";
      SI.Length footWidth
        "Overall foot width used to scale the v0.3 plantar contact discretization";
      SI.Length ankleFromHeel
        "Anterior distance from heel reference to ankle-frame origin";
      SI.Length ankleHeight
        "Vertical ankle-frame height above the plantar/heel reference";
    
      SI.Length shankLength
        "Knee-to-ankle joint-centre distance";
      SI.Length thighLength
        "Hip-to-knee joint-centre distance";
    
      SI.Length pelvisLength
        "Reduced lower-trunk/pelvis cranio-caudal length used by the current reduced model";
      SI.Length hipCenterDistance
        "Distance between left and right hip-centre frames";
    
      String populationKey = "deLeva1996"
        "Source/dataset selector; current implementation uses de Leva mass/COM/radius data";
      String geometrySourceId = "EXPLICIT_SUBJECT_INPUT"
        "Source identifier for dimensional geometry inputs";
    end AnthropometryProfile;
  
    record BSIPCoefficients
      "Dimensionless body-segment inertial coefficients"
      Real massFraction(min=0)
        "Segment mass divided by whole-body mass";
      Real comFraction(min=0)
        "COM location divided by segment reference length, from source-defined proximal/origin endpoint";
      Real kSagittal(min=0)
        "Radius of gyration / segment length, source sagittal convention";
      Real kTransverse(min=0)
        "Radius of gyration / segment length, source transverse convention";
      Real kLongitudinal(min=0)
        "Radius of gyration / segment length, source longitudinal convention";
      String sourceId;
    end BSIPCoefficients;
  
    record SegmentProperties
      "Resolved segment mass properties"
      import SI = Modelica.Units.SI;
    
      SI.Mass mass;
      SI.Length length;
      Real comFraction(min=0);
      SI.Length comDistance
        "Distance from source-defined segment origin to COM";
      SI.Inertia ISagittal;
      SI.Inertia ITransverse;
      SI.Inertia ILongitudinal;
      String sourceId;
    end SegmentProperties;
  
    record JointMobilityProfile
      "Subject/task-specific ROM limits; values must be source-traceable outside examples"
      import SI = Modelica.Units.SI;
    
      parameter Integer n(min=1)=1;
      SI.Angle qMin[n];
      SI.Angle qMax[n];
      SI.Angle softLimitWidth[n] = fill(0, n);
      Real limitStiffness[n](each unit="N.m/rad") = fill(0, n);
      Real limitDamping[n](each unit="N.m.s/rad") = fill(0, n);
      String sourceId = "UNSET";
      ModelicaHumanBodyPArts.Types.ROMNature romNature = ModelicaHumanBodyPArts.Types.ROMNature.Unknown;
      String measurementMethod = "UNSET";
      String measurementPosture = "UNSET";
      String populationDescription = "UNSET";
      Boolean hasUncertainty = false;
      SI.Angle qMinStd[n] = fill(0, n)
        "Optional standard uncertainty/SD descriptor for lower limit; interpretation documented by source";
      SI.Angle qMaxStd[n] = fill(0, n)
        "Optional standard uncertainty/SD descriptor for upper limit; interpretation documented by source";
      String distributionDescription = "";
      Integer sampleSizeSubjects=0;
      SI.Angle measurementResolution=0 "Recording resolution, not a standard error";
      String uncertaintyMeaning="UNSET";
      String coordinateMappingStatus="UNSET";
      String side="UNSET";
    end JointMobilityProfile;
  
    record ProvenanceInfo
      "Machine-readable provenance tag for important model information"
      ModelicaHumanBodyPArts.Types.ProvenanceClass provenanceClass =
        ModelicaHumanBodyPArts.Types.ProvenanceClass.ExplicitModelAssumption;
      String sourceId = "UNSET";
      String citation = "";
      String notes = "";
    end ProvenanceInfo;
  
    record SegmentProperties3D
      "Full 3-D segment mass properties in an explicitly identified segment frame"
      import SI = Modelica.Units.SI;
    
      SI.Mass mass;
      SI.Length length;
      SI.Position rCM[3]
        "COM position resolved in the declared segment coordinate system";
      SI.Inertia I_CM[3,3]
        "Inertia tensor about COM, resolved in the declared segment coordinate system";
      Real R_principal[3,3]
        "Orientation matrix of principal inertia axes relative to the segment frame";
      String segmentFrameId = "UNSET"
        "Identifier for the anatomical/segment coordinate-system convention";
      ModelicaHumanBodyPArts.Records.ProvenanceInfo provenance;
    end SegmentProperties3D;
  
    record JointMobilityMetadata
      "Measurement context and uncertainty metadata kept separate from executable ROM limits"
      ModelicaHumanBodyPArts.Types.ROMNature romNature = ModelicaHumanBodyPArts.Types.ROMNature.Unknown;
      String jointCoordinateConvention = "UNSET";
      String measurementMethod = "UNSET";
      String measurementPosture = "UNSET";
      String populationDescription = "UNSET";
      String ageRange = "UNSET";
      String sexPopulation = "UNSET";
      Boolean hasDistribution = false;
      String distributionDescription = "";
      ModelicaHumanBodyPArts.Records.ProvenanceInfo provenance;
    end JointMobilityMetadata;
  
    record PublishedBSIPRow
      "Source-frame coefficients only; NOT resolved body properties"
      Real massFraction=0;
      Real lengthPerStature=0;
      Real beta[3]=zeros(3) "Signed COM fractions, in published source-frame order x,y,z";
      Real eta[3]=zeros(3) "Diagonal radii / source reference length, x,y,z";
      Real crossEta[3]=zeros(3) "Signed cross radii / length, source order xy,yz,xz";
      Boolean hasCrossRadii=false;
      Boolean tensorConversionApproved=false
        "False until signs, reference landmarks and side convention are audited";
      String sourceId="UNSET";
      String frameId="BOVA2020_X_ANTERIOR_Y_LEFT_Z_SUPERIOR";
      String referenceLengthDefinition="UNRESOLVED";
      String sourcePopulation="Published rider-model table; no inferred female table";
      String originNote="Origins per Bova Table 1 and Appendix A; not generic heel origin";
      String evidence="Published-source transcription only; no new human validation";
    end PublishedBSIPRow;
  
  end Records;

