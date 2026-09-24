within ;
package ModelicaHumanBodyPArts
  "Parametric human-body parts: current implemented research components"
  extends Modelica.Icons.Package;
  annotation(
    version="0.10.0",
    uses(Modelica(version="4.1.0")),
    Documentation(info="<html><p>v0.10.0 release-candidate source edition. v0.9.2 remains frozen. "
      + " Core mechanics descend from tested v0.7.3; subsequent axial and transmission repairs are documented;"
      + " historical scalar replays imported from the v0.8 branch."
      + " Full-body, upper-limb and dyadic assemblies remain design specifications."
      + " This is not human biomechanical or clinical validation."
      + " No confidential PhD material is used."
      + " Consult the included Test Report for platform-specific execution status."
      + " Package names are case-sensitive.</p></html>"));

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

  package Data
    extends Modelica.Icons.Package;
  
    package DeLeva1996
      "Subset of adjusted Zatsiorsky-Seluyanov coefficients used for v0.2 lower body"
      extends Modelica.Icons.Package;
    
      function female
        input ModelicaHumanBodyPArts.Types.SegmentKey segment;
        output ModelicaHumanBodyPArts.Records.BSIPCoefficients c;
      algorithm
        if segment == ModelicaHumanBodyPArts.Types.SegmentKey.Foot then
          c := ModelicaHumanBodyPArts.Records.BSIPCoefficients(
            massFraction=0.0129,
            comFraction=0.4014,
            kSagittal=0.299,
            kTransverse=0.279,
            kLongitudinal=0.139,
            sourceId="de Leva 1996, female, foot");
        elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Shank then
          c := ModelicaHumanBodyPArts.Records.BSIPCoefficients(
            massFraction=0.0481,
            comFraction=0.4352,
            kSagittal=0.267,
            kTransverse=0.263,
            kLongitudinal=0.092,
            sourceId="de Leva 1996, female shank, knee-joint-centre to ankle-joint-centre endpoint set");
        elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Thigh then
          c := ModelicaHumanBodyPArts.Records.BSIPCoefficients(
            massFraction=0.1478,
            comFraction=0.3612,
            kSagittal=0.369,
            kTransverse=0.364,
            kLongitudinal=0.162,
            sourceId="de Leva 1996, female, thigh");
        else
          c := ModelicaHumanBodyPArts.Records.BSIPCoefficients(
            massFraction=0.1247,
            comFraction=0.4920,
            kSagittal=0.433,
            kTransverse=0.402,
            kLongitudinal=0.444,
            sourceId="de Leva 1996, female, lower trunk/pelvis");
        end if;
      end female;
    
      function male
        input ModelicaHumanBodyPArts.Types.SegmentKey segment;
        output ModelicaHumanBodyPArts.Records.BSIPCoefficients c;
      algorithm
        if segment == ModelicaHumanBodyPArts.Types.SegmentKey.Foot then
          c := ModelicaHumanBodyPArts.Records.BSIPCoefficients(
            massFraction=0.0137,
            comFraction=0.4415,
            kSagittal=0.257,
            kTransverse=0.245,
            kLongitudinal=0.124,
            sourceId="de Leva 1996, male, foot");
        elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Shank then
          c := ModelicaHumanBodyPArts.Records.BSIPCoefficients(
            massFraction=0.0433,
            comFraction=0.4395,
            kSagittal=0.251,
            kTransverse=0.246,
            kLongitudinal=0.102,
            sourceId="de Leva 1996, male shank, knee-joint-centre to ankle-joint-centre endpoint set");
        elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Thigh then
          c := ModelicaHumanBodyPArts.Records.BSIPCoefficients(
            massFraction=0.1416,
            comFraction=0.4095,
            kSagittal=0.329,
            kTransverse=0.329,
            kLongitudinal=0.149,
            sourceId="de Leva 1996, male, thigh");
        else
          c := ModelicaHumanBodyPArts.Records.BSIPCoefficients(
            massFraction=0.1117,
            comFraction=0.6115,
            kSagittal=0.615,
            kTransverse=0.551,
            kLongitudinal=0.587,
            sourceId="de Leva 1996, male, lower trunk/pelvis");
        end if;
      end male;
    
      function coefficients
        input ModelicaHumanBodyPArts.Types.SegmentKey segment;
        input ModelicaHumanBodyPArts.Types.Sex sex;
        output ModelicaHumanBodyPArts.Records.BSIPCoefficients c;
      protected
        ModelicaHumanBodyPArts.Records.BSIPCoefficients cf;
        ModelicaHumanBodyPArts.Records.BSIPCoefficients cm;
      algorithm
        cf := female(segment);
        cm := male(segment);
    
        if sex == ModelicaHumanBodyPArts.Types.Sex.Female then
          c := cf;
        elseif sex == ModelicaHumanBodyPArts.Types.Sex.Male then
          c := cm;
        else
          c := ModelicaHumanBodyPArts.Records.BSIPCoefficients(
            massFraction=0.5*(cf.massFraction + cm.massFraction),
            comFraction=0.5*(cf.comFraction + cm.comFraction),
            kSagittal=0.5*(cf.kSagittal + cm.kSagittal),
            kTransverse=0.5*(cf.kTransverse + cm.kTransverse),
            kLongitudinal=0.5*(cf.kLongitudinal + cm.kLongitudinal),
            sourceId=
        "Arithmetic mean of de Leva 1996 female/male coefficients; not a published population");
        end if;
      end coefficients;
    
      annotation(Documentation(info="<html>\n  <p>The numerical coefficients in this package are a v0.2 " +
        "transcription of\n  de Leva (1996) adjusted Zatsiorsky-Seluyanov body-segment " +
        "inertial\n  parameters for the lower body. The pelvis uses the lower-trunk " +
        "partition.</p>\n  <p>v0.6 selects the alternate shank coefficients normalized " +
        "to the\n  knee-joint-centre to ankle-joint-centre length, because " +
        "AnthropometryProfile\n  defines shankLength using those endpoints. The earlier " +
        "v0.5 shank row mixed\n  endpoint conventions and incorrect radius values.</p>\n " +
        " <p>v0.7.1: all 30 female/male foot, shank and thigh scalars match the " +
        "HAS-Motion implementation tables retrieved 2026-09-21. This is " +
        "source-transcription verification, not independent anatomy validation. The " +
        "original de Leva Table 4 was not directly visually audited in this milestone. " +
        "The lower-trunk row is outside this check.</p>\n  <p><b>Important:</b> segment " +
        "lengths are not inferred here. They come from\n  AnthropometryProfile " +
        "measurements/inputs. This avoids silently mixing\n  incompatible endpoint " +
        "definitions before the dedicated length-law\n  validation pass.</p>\n  </html>"));
    end DeLeva1996;
  
    package RoaasAndersson1982
      "Side-specific passive ROM means and between-subject SDs, source Table 1"
      extends Modelica.Icons.Package;
      function hipMean
        input Boolean isLeft=true;
        output ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(n=3);
      algorithm
        rom.qMin := (Modelica.Constants.pi/180)*(if isLeft then {-9.5,-38.4,-33.7} else {-9.4,-38.8,-33.6});
        rom.qMax := (Modelica.Constants.pi/180)*(if isLeft then {120.4,30.5,32.5} else {120.3,30.5,32.6});
        rom.qMinStd := (Modelica.Constants.pi/180)*(if isLeft then {5.2,7.3,6.7} else {5.3,7.0,6.8});
        rom.qMaxStd := (Modelica.Constants.pi/180)*(if isLeft then {8.3,7.3,8.2} else {8.3,7.3,8.2});
        rom.softLimitWidth := fill(0,3);
        rom.limitStiffness := fill(0,3);
        rom.limitDamping := fill(0,3);
        rom.romNature := ModelicaHumanBodyPArts.Types.ROMNature.Passive;
        rom.measurementMethod := "Ordinary goniometer; AAOS techniques; one examiner; nearest 5 degrees";
        rom.measurementPosture :=
        "Flexion supine, opposite hip held on abdomen; extension/rotation prone with " +
        "knee flexed; ab/adduction supine knee extended";
        rom.populationDescription :=
        "Healthy males aged 30-40, sampled in Goteborg; not a universal population";
        rom.sourceId := "Roaas-Andersson 1982, DOI 10.3109/17453678208992202, Table 1 p206";
        rom.side := if isLeft then "Left" else "Right";
        rom.sampleSizeSubjects := 105;
        rom.measurementResolution := Modelica.Constants.pi/36;
        rom.hasUncertainty := true;
        rom.uncertaintyMeaning :=
        "Between-subject standard deviation; NOT uncertainty of a measured subject or standard error";
        rom.distributionDescription :=
        "Reported approximately normal marginal distributions; covariance and " +
        "subject-level data unavailable";
        rom.coordinateMappingStatus :=
        "Clinical directions mapped to reduced library axes; landmark-level validation pending";
      end hipMean;
      function kneeMean
        input Boolean isLeft=true;
        output ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(n=1);
      algorithm
        rom.qMin := (Modelica.Constants.pi/180)*(if isLeft then {-1.7} else {-1.6});
        rom.qMax := (Modelica.Constants.pi/180)*(if isLeft then {143.7} else {143.8});
        rom.qMinStd := (Modelica.Constants.pi/180)*(if isLeft then {3.0} else {2.8});
        rom.qMaxStd := (Modelica.Constants.pi/180)*(if isLeft then {6.6} else {6.4});
        rom.softLimitWidth := fill(0,1);
        rom.limitStiffness := fill(0,1);
        rom.limitDamping := fill(0,1);
        rom.romNature := ModelicaHumanBodyPArts.Types.ROMNature.Passive;
        rom.measurementMethod := "Ordinary goniometer; AAOS techniques; one examiner; nearest 5 degrees";
        rom.measurementPosture := "Supine; full extension zero; hyperextension negative";
        rom.populationDescription :=
        "Healthy males aged 30-40, sampled in Goteborg; not a universal population";
        rom.sourceId := "Roaas-Andersson 1982, DOI 10.3109/17453678208992202, Table 1 p206";
        rom.side := if isLeft then "Left" else "Right";
        rom.sampleSizeSubjects := 90;
        rom.measurementResolution := Modelica.Constants.pi/36;
        rom.hasUncertainty := true;
        rom.uncertaintyMeaning :=
        "Between-subject standard deviation; NOT uncertainty of a measured subject or standard error";
        rom.distributionDescription :=
        "Reported approximately normal marginal distributions; covariance and " +
        "subject-level data unavailable";
        rom.coordinateMappingStatus := "Single flexion coordinate; axis verification separate";
      end kneeMean;
      function ankleMean
        input Boolean isLeft=true;
        output ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(n=2);
      algorithm
        rom.qMin := (Modelica.Constants.pi/180)*(if isLeft then {-39.6,-27.9} else {-39.7,-27.6});
        rom.qMax := (Modelica.Constants.pi/180)*(if isLeft then {15.3,27.8} else {15.3,27.7});
        rom.qMinStd := (Modelica.Constants.pi/180)*(if isLeft then {7.7,5.0} else {7.5,4.6});
        rom.qMaxStd := (Modelica.Constants.pi/180)*(if isLeft then {5.8,6.9} else {5.8,6.9});
        rom.softLimitWidth := fill(0,2);
        rom.limitStiffness := fill(0,2);
        rom.limitDamping := fill(0,2);
        rom.romNature := ModelicaHumanBodyPArts.Types.ROMNature.Passive;
        rom.measurementMethod := "Ordinary goniometer; AAOS techniques; one examiner; nearest 5 degrees";
        rom.measurementPosture := "Supine; knee flexion approximately 45 degrees";
        rom.populationDescription :=
        "Healthy males aged 30-40, sampled in Goteborg; not a universal population";
        rom.sourceId := "Roaas-Andersson 1982, DOI 10.3109/17453678208992202, Table 1 p206";
        rom.side := if isLeft then "Left" else "Right";
        rom.sampleSizeSubjects := 96;
        rom.measurementResolution := Modelica.Constants.pi/36;
        rom.hasUncertainty := true;
        rom.uncertaintyMeaning :=
        "Between-subject standard deviation; NOT uncertainty of a measured subject or standard error";
        rom.distributionDescription :=
        "Reported approximately normal marginal distributions; covariance and " +
        "subject-level data unavailable";
        rom.coordinateMappingStatus :=
        "DF/PF plus composite foot varus/valgus: latter NOT an isolated subtalar coordinate";
      end ankleMean;
      annotation(Documentation(info="<html><p>Transcribed from the original Table 1, p206.
     Means and SDs are stored by side. Original passive varus/valgus measurements
     combine several foot movements and do not validate an isolated inversion hinge.
     Using these as independent hard bounds remains a modelling assumption.</p></html>"));
    end RoaasAndersson1982;
  
    package Bova2020LowerLimb
      "Audited raw A1/A5/A6 tables, not enabled in the active body generator"
      extends Modelica.Icons.Package;
    
      function deLevaRiderRow
        input ModelicaHumanBodyPArts.Types.SegmentKey segment;
        output ModelicaHumanBodyPArts.Records.PublishedBSIPRow c;
      algorithm
        if segment == ModelicaHumanBodyPArts.Types.SegmentKey.Thigh then
          c := ModelicaHumanBodyPArts.Records.PublishedBSIPRow(
            massFraction=0.1416, lengthPerStature=0.2425,
            beta={0,0,-0.4095}, eta={0.329,0.329,0.149},
            crossEta={0,0,0}, hasCrossRadii=false,
            tensorConversionApproved=false,
            sourceId="Bova2020_Table_A1_Thigh",
            referenceLengthDefinition="Bova A1 thigh reference: gamma*stature; HJC-KJC model geometry");
        elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Shank then
          c := ModelicaHumanBodyPArts.Records.PublishedBSIPRow(
            massFraction=0.0433, lengthPerStature=0.2493,
            beta={0,0,-0.4459}, eta={0.255,0.249,0.103},
            crossEta={0,0,0}, hasCrossRadii=false,
            tensorConversionApproved=false,
            sourceId="Bova2020_Table_A1_Shank",
            referenceLengthDefinition=
        "de Leva upper-table normalization; LMAL in Bova A.1, AJC in Table 1; NOT " +
        "interchangeable with current KJC-AJC input");
        elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Foot then
          c := ModelicaHumanBodyPArts.Records.PublishedBSIPRow(
            massFraction=0.0137, lengthPerStature=0.1482,
            beta={0.4415,0,-0.1244}, eta={0.124,0.245,0.257},
            crossEta={0,0,0}, hasCrossRadii=false,
            tensorConversionApproved=false,
            sourceId="Bova2020_Table_A1_Foot",
            referenceLengthDefinition=
        "HEEL-TTIP reference length with Bova heel/ankle offset assumptions; not generic ankle-centred COM");
        else
          c := ModelicaHumanBodyPArts.Records.PublishedBSIPRow();
          assert(false, "Only thigh, shank and foot are transcribed in this source package.");
        end if;
      end deLevaRiderRow;
    
      function dumasRiderRow
        input ModelicaHumanBodyPArts.Types.SegmentKey segment;
        output ModelicaHumanBodyPArts.Records.PublishedBSIPRow c;
      algorithm
        if segment == ModelicaHumanBodyPArts.Types.SegmentKey.Thigh then
          c := ModelicaHumanBodyPArts.Records.PublishedBSIPRow(
            massFraction=0.123, lengthPerStature=0.2441,
            beta={-0.041,-0.033,-0.429}, eta={0.29,0.3,0.15},
            crossEta={0.02,0.07,0.07}, hasCrossRadii=true,
            tensorConversionApproved=false,
            sourceId="Bova2020_Table_A5/A6_Thigh",
            referenceLengthDefinition="Bova A5/A6 thigh reference: gamma*stature; HJC-KJC model geometry");
        elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Shank then
          c := ModelicaHumanBodyPArts.Records.PublishedBSIPRow(
            massFraction=0.048, lengthPerStature=0.2446,
            beta={-0.048,-0.007,-0.41}, eta={0.28,0.28,0.1},
            crossEta={0.02,-0.05,-0.04}, hasCrossRadii=true,
            tensorConversionApproved=false,
            sourceId="Bova2020_Table_A5/A6_Shank",
            referenceLengthDefinition=
        "Bova A5 shank reference: gamma*stature; original Dumas landmarks require audit");
        elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Foot then
          c := ModelicaHumanBodyPArts.Records.PublishedBSIPRow(
            massFraction=0.012, lengthPerStature=0.1034,
            beta={0.382,-0.026,-0.151}, eta={0.17,0.36,0.37},
            crossEta={0.08,0,0.13}, hasCrossRadii=true,
            tensorConversionApproved=false,
            sourceId="Bova2020_Table_A5/A6_Foot",
            referenceLengthDefinition=
        "Bova A5 reference length gamma*stature; NOT full heel-to-toe footLength");
        else
          c := ModelicaHumanBodyPArts.Records.PublishedBSIPRow();
          assert(false, "Only thigh, shank and foot are transcribed in this source package.");
        end if;
      end dumasRiderRow;
    
      annotation(Documentation(info=
        "<html><p>Source: Bova, Massaro and Petrone (2020), Applied Sciences 10:4509, " +
        "DOI 10.3390/app10134509, Tables A1, A5, A6. CC BY 4.0. Values divided by 100 " +
        "from printed percentages.</p><p>The rider-model transformations are already " +
        "included. These functions preserve source values and do not select a body " +
        "model. resolveSegment remains unchanged. Signed cross radii are not squared " +
        "into a tensor until the product-sign convention and side/landmarks are checked. " +
        "No female MYD row is inferred.</p></html>"));
    end Bova2020LowerLimb;
  
  end Data;

  package Scaling
    extends Modelica.Icons.FunctionsPackage;
  
    function segmentLength
      input ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      input ModelicaHumanBodyPArts.Types.SegmentKey segment;
      output Modelica.Units.SI.Length L;
    algorithm
      if segment == ModelicaHumanBodyPArts.Types.SegmentKey.Foot then
        L := profile.footLength;
      elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Shank then
        L := profile.shankLength;
      elseif segment == ModelicaHumanBodyPArts.Types.SegmentKey.Thigh then
        L := profile.thighLength;
      else
        L := profile.pelvisLength;
      end if;
      assert(L > 0, "Segment length must be positive.");
    end segmentLength;
  
    function resolveSegment
      "Resolve mass, COM distance and principal inertias from profile + public BSIP data"
      import SI = Modelica.Units.SI;
    
      input ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      input ModelicaHumanBodyPArts.Types.SegmentKey segment;
      output ModelicaHumanBodyPArts.Records.SegmentProperties props;
    
    protected
      ModelicaHumanBodyPArts.Records.BSIPCoefficients c;
      SI.Length L;
      SI.Mass m;
    algorithm
      assert(profile.mass > 0, "Whole-body mass must be positive.");
      assert(profile.height > 0, "Stature must be positive.");
    
      c := ModelicaHumanBodyPArts.Data.DeLeva1996.coefficients(segment, profile.sex);
      L := ModelicaHumanBodyPArts.Scaling.segmentLength(profile, segment);
      m := profile.mass*c.massFraction;
    
      props.mass := m;
      props.length := L;
      props.comFraction := c.comFraction;
      props.comDistance := c.comFraction*L;
    
      // Radii of gyration are dimensionless fractions of the source segment length.
      props.ISagittal := m*(c.kSagittal*L)^2;
      props.ITransverse := m*(c.kTransverse*L)^2;
      props.ILongitudinal := m*(c.kLongitudinal*L)^2;
      props.sourceId := c.sourceId;
    
      assert(props.mass > 0, "Resolved segment mass must be positive.");
      assert(props.ISagittal > 0 and props.ITransverse > 0 and props.ILongitudinal > 0,
        "Resolved principal inertias must be positive.");
      assert(ModelicaHumanBodyPArts.Utilities.physicalInertia(
        diagonal({props.ISagittal,props.ITransverse,props.ILongitudinal})),
        "Principal inertias violate physical mass-distribution constraints.");
    end resolveSegment;
  
  end Scaling;

  package Base
    extends Modelica.Icons.BasesPackage;
  
    partial model PartialLongSegment
      "Rigid lower-limb segment with neutral anatomical axes (+x anterior, +y left, +z superior)"
      import SI = Modelica.Units.SI;
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties props;
      parameter Boolean animation=true;
      parameter SI.Length visualWidth=0.08;
      parameter SI.Length visualHeight=0.08;
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_proximal;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_distal;
    
    protected
      Modelica.Mechanics.MultiBody.Parts.BodyShape body(
        animation=animation,
        animateSphere=animation,
        r={0,0,-props.length},
        r_CM={0,0,-props.comDistance},
        m=props.mass,
        I_11=props.ISagittal,
        I_22=props.ITransverse,
        I_33=props.ILongitudinal,
        I_21=0,
        I_31=0,
        I_32=0,
        shapeType="cylinder",
        length=props.length,
        width=visualWidth,
        height=visualHeight,
        lengthDirection={0,0,-1},
        widthDirection={1,0,0});
    
    equation
      connect(frame_proximal, body.frame_a);
      connect(body.frame_b, frame_distal);
    
      annotation(Documentation(info="<html>
      <p>v0.6 neutral lower-limb convention: +x is anterior/forward, +y is leftward,
      and +z is superior/upward. Therefore a proximal-to-distal lower-limb vector
      is along -z. This removes the earlier conflict in which long segments used
      +z distally while the foot/contact/world logic used z-up. The mapping of
      de Leva inertia axes to local x/y/z remains a separate validation item.</p>
      </html>"));
    end PartialLongSegment;
  
    model RigidSegment3D
      "Full-tensor rigid segment; explicit COM/frame data required"
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D props;
      parameter Modelica.Units.SI.Position rDistal[3];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_proximal;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_distal;
    protected
      Modelica.Mechanics.MultiBody.Parts.BodyShape body(
        animation=false,r=rDistal,r_CM=props.rCM,m=props.mass,
        I_11=props.I_CM[1,1],I_22=props.I_CM[2,2],I_33=props.I_CM[3,3],
        I_21=props.I_CM[2,1],I_31=props.I_CM[3,1],I_32=props.I_CM[3,2]);
    equation
      assert(props.mass>0 and ModelicaHumanBodyPArts.Utilities.physicalInertia(props.I_CM),
        "Mass must be positive and the COM inertia physically realizable.");
      connect(frame_proximal,body.frame_a);
      connect(frame_distal,body.frame_b);
      annotation(Documentation(info="<html><p>Modelica BodyShape expects the inertia about
      COM resolved parallel to frame_a. R_principal is metadata here: I_CM is already
      expressed in the segment frame and is not rotated twice. Population data and
      anatomical frame definitions remain required before biological interpretation.</p></html>"));
    end RigidSegment3D;
  
  end Base;

  package Segments
    extends Modelica.Icons.Package;
  
    model Thigh
      extends ModelicaHumanBodyPArts.Base.PartialLongSegment;
    end Thigh;
  
    model Shank
      extends ModelicaHumanBodyPArts.Base.PartialLongSegment;
    end Shank;
  
    model Foot
      "Rigid foot with six distributed plantar contact frames"
      import SI = Modelica.Units.SI;
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties props;
      parameter SI.Length footWidth;
      parameter SI.Length ankleFromHeel;
      parameter SI.Length ankleHeight;
      parameter SI.Length comAboveSole=0
        "Explicit COM vertical offset above sole; zero preserves the unvalidated legacy assumption";
      parameter String comOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE"
        "Provenance label for this offset, not evidence of anatomical validation";
      output SI.Position comPositionLocal[3] "COM resolved in the ankle frame";
      parameter Boolean animation=true;
      parameter Boolean isLeft=true
        "True for left foot; controls medial/lateral landmark mirroring";
    
      // Named frames retained for experiment/controller readability.
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_ankle;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_heel;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_midfoot;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_toe;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_medial;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_lateral;
    
      // Six-zone contact array:
      // 1 heel-medial, 2 heel-lateral,
      // 3 midfoot-medial, 4 midfoot-lateral,
      // 5 forefoot-medial, 6 forefoot-lateral.
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_plantar[6];
    
    protected
      parameter Real medialSign = if isLeft then -1 else 1;
      parameter Real lateralSign = -medialSign;
    
      // Neutral foot axes: +x anterior/heel->toe, +y leftward, +z superior/upward.
      // Therefore medial/lateral y signs depend on side.
      parameter SI.Position rCM[3] = {
        props.comDistance - ankleFromHeel,
        0,
        -ankleHeight + comAboveSole};
    
      Modelica.Mechanics.MultiBody.Parts.Body body(
        animation=false,
        r_CM=rCM,
        m=props.mass,
        I_11=props.ILongitudinal,
        I_22=props.ITransverse,
        I_33=props.ISagittal,
        I_21=0,
        I_31=0,
        I_32=0);
    
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation heel(
        r={-ankleFromHeel,0,-ankleHeight}, animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation midfoot(
        r={0.50*props.length-ankleFromHeel,0,-ankleHeight}, animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation toe(
        r={props.length-ankleFromHeel,0,-ankleHeight}, animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation medial(
        r={0.65*props.length-ankleFromHeel,medialSign*0.25*footWidth,-ankleHeight},
        animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation lateral(
        r={0.65*props.length-ankleFromHeel,lateralSign*0.25*footWidth,-ankleHeight},
        animation=false);
    
      // Contact discretization points. Their normalized locations are model
      // discretization choices, not claimed anatomical landmarks.
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z1(
        r={0.12*props.length-ankleFromHeel,medialSign*0.28*footWidth,-ankleHeight},
        animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z2(
        r={0.12*props.length-ankleFromHeel,lateralSign*0.28*footWidth,-ankleHeight},
        animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z3(
        r={0.50*props.length-ankleFromHeel,medialSign*0.38*footWidth,-ankleHeight},
        animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z4(
        r={0.50*props.length-ankleFromHeel,lateralSign*0.38*footWidth,-ankleHeight},
        animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z5(
        r={0.82*props.length-ankleFromHeel,medialSign*0.32*footWidth,-ankleHeight},
        animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z6(
        r={0.82*props.length-ankleFromHeel,lateralSign*0.32*footWidth,-ankleHeight},
        animation=false);
    
      Modelica.Mechanics.MultiBody.Visualizers.FixedShape footShape(
        animation=animation,
        shapeType="box",
        r_shape={-ankleFromHeel,0,-ankleHeight},
        lengthDirection={1,0,0},
        widthDirection={0,1,0},
        length=props.length,
        width=footWidth,
        height=0.04);
    
    equation
      assert(comAboveSole>=0, "The declared above-sole COM offset must be nonnegative.");
      assert(comAboveSole<=0 or comOffsetSourceId<>"ASSUMPTION_LEGACY_SOLE_PLANE",
        "A nonzero COM offset requires its own explicit provenance label.");
      comPositionLocal = rCM;
      connect(frame_ankle, body.frame_a);
      connect(frame_ankle, heel.frame_a);
      connect(frame_ankle, midfoot.frame_a);
      connect(frame_ankle, toe.frame_a);
      connect(frame_ankle, medial.frame_a);
      connect(frame_ankle, lateral.frame_a);
      connect(frame_ankle, z1.frame_a);
      connect(frame_ankle, z2.frame_a);
      connect(frame_ankle, z3.frame_a);
      connect(frame_ankle, z4.frame_a);
      connect(frame_ankle, z5.frame_a);
      connect(frame_ankle, z6.frame_a);
      connect(frame_ankle, footShape.frame_a);
    
      connect(heel.frame_b, frame_heel);
      connect(midfoot.frame_b, frame_midfoot);
      connect(toe.frame_b, frame_toe);
      connect(medial.frame_b, frame_medial);
      connect(lateral.frame_b, frame_lateral);
    
      connect(z1.frame_b, frame_plantar[1]);
      connect(z2.frame_b, frame_plantar[2]);
      connect(z3.frame_b, frame_plantar[3]);
      connect(z4.frame_b, frame_plantar[4]);
      connect(z5.frame_b, frame_plantar[5]);
      connect(z6.frame_b, frame_plantar[6]);
    
      annotation(Documentation(info="<html>
      <p>The default comAboveSole=0 places the COM on the sole plane. This is an
      unvalidated legacy modelling assumption, not a published anatomical COM height.
      A nonzero offset requires an explicit source label and independent source/frame
      reconciliation; supplying that label alone does not validate the offset.</p>
      <p>The six zones are introduced to support the canonical distributed-contact
      reconstruction. Their normalized x/y locations are currently explicit
      <b>contact discretization parameters</b>, not validated anatomical constants.
      Validation against foot geometry / pressure-platform data remains pending.</p>
      <p>v0.6 mirrors medial/lateral landmark signs by side. The previous shared
      left/right geometry mislabeled the right-foot medial and lateral zones.</p>
      </html>"));
    end Foot;
  
    model Pelvis
      "Reduced lower-trunk/pelvis body exposing two hip-centre frames"
      import SI = Modelica.Units.SI;
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties props;
      parameter SI.Length hipCenterDistance;
      parameter Boolean animation=true;
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_proximal;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_leftHip;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_rightHip;
    
    protected
      Modelica.Mechanics.MultiBody.Parts.BodyShape body(
        animation=animation,
        r={0,0,-props.length},
        r_CM={0,0,-props.comDistance},
        m=props.mass,
        I_11=props.ISagittal,
        I_22=props.ITransverse,
        I_33=props.ILongitudinal,
        I_21=0,
        I_31=0,
        I_32=0,
        shapeType="box",
        length=props.length,
        width=hipCenterDistance,
        height=0.12,
        lengthDirection={0,0,-1},
        widthDirection={0,1,0});
    
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation leftHip(
        r={0,0.5*hipCenterDistance,-props.length},
        animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation rightHip(
        r={0,-0.5*hipCenterDistance,-props.length},
        animation=false);
    
    equation
      connect(frame_proximal, body.frame_a);
      connect(frame_proximal, leftHip.frame_a);
      connect(frame_proximal, rightHip.frame_a);
      connect(leftHip.frame_b, frame_leftHip);
      connect(rightHip.frame_b, frame_rightHip);
    
      annotation(Documentation(info="<html>
      <p>This is a reduced pelvis/lower-trunk representation for implementation
      staging. The de Leva lower-trunk mass/inertia partition is used, while
      pelvis length and hip-centre spacing remain explicit subject inputs. In v0.6
      the proximal pelvis/trunk frame is superior to the hip frames, so neutral
      lower-limb geometry extends along world/local -z without a corrective 180-degree
      assembly rotation.</p>
      </html>"));
    end Pelvis;
  
  end Segments;

  package Joints
    extends Modelica.Icons.Package;
  
    model Knee
      "Reduced 1-DOF knee flexion/extension"
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=1);
      parameter Modelica.Units.SI.Angle phi_start=0;
      parameter Boolean phi_fixed=false
        "Fix initial knee coordinate for verification/prescribed initial configurations";
    
      parameter Modelica.Units.SI.AngularVelocity w_start=0;
      parameter Boolean w_fixed=false "Fix initial angular velocity only on request";
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b;
    
      output Modelica.Units.SI.Angle q;
      output Real limitUtilization;
      output Modelica.Units.SI.Angle distanceToLimit;
    
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute rev(
        n={0,1,0},
        phi(start=phi_start, fixed=phi_fixed),
        w(start=w_start, fixed=w_fixed));
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=1, mobility=mobility);
    
    equation
      connect(frame_a, rev.frame_a);
      connect(rev.frame_b, frame_b);
    
      q = rev.phi;
      monitor.q = {q};
      limitUtilization = monitor.utilization[1];
      distanceToLimit = monitor.distanceToLimit[1];
    end Knee;
  
    model AnkleComplex
      "Reduced serial 2-DOF ankle complex with library-axis mapping of ISB clinical motions"
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=2);
      parameter Modelica.Units.SI.Angle q_start[2]={0,0};
      parameter Boolean q_fixed[2]=fill(false,2)
        "Fix initial joint coordinates for verification/prescribed initial configurations";
      parameter Modelica.Units.SI.AngularVelocity w_start[2]=fill(0,2);
      parameter Boolean w_fixed[2]=fill(false,2)
        "Fix initial angular velocities only when explicitly requested";
      parameter Boolean isLeft=true
        "Side-aware inversion/eversion sign";
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a "Shank distal";
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b "Foot proximal";
    
      output Modelica.Units.SI.Angle q[2];
      output Real limitUtilization[2];
      output Integer limitingDOF;
    
    protected
      // v0.6 library neutral axes are +x anterior, +y leftward, +z superior.
      // q1 dorsiflexion (+): rotation about -y raises the forefoot (+z).
      // q2 inversion (+): floating anterior axis; sign depends on side so the
      // medial border elevates for positive inversion.
      Modelica.Mechanics.MultiBody.Joints.Revolute dorsiPlantar(
        n={0,-1,0},
        phi(start=q_start[1], fixed=q_fixed[1]),
        w(start=w_start[1], fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute inversionEversion(
        n=if isLeft then {-1,0,0} else {1,0,0},
        phi(start=q_start[2], fixed=q_fixed[2]),
        w(start=w_start[2], fixed=w_fixed[2]));
    
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=2, mobility=mobility);
    
    equation
      connect(frame_a, dorsiPlantar.frame_a);
      connect(dorsiPlantar.frame_b, inversionEversion.frame_a);
      connect(inversionEversion.frame_b, frame_b);
    
      q = {dorsiPlantar.phi, inversionEversion.phi};
      monitor.q = q;
      limitUtilization = monitor.utilization;
      limitingDOF = monitor.limitingDOF;
    
      annotation(Documentation(info="<html>
      <p>v0.6 corrects the same axis-letter mapping error found at the hip. In the
      library's neutral axes, dorsiflexion/plantarflexion is a side-to-side y-axis
      rotation, not a rotation around the shank longitudinal z axis. The floating
      inversion/eversion axis is anterior x and is mirrored by side.</p>
      <p>The third axial rotation remains a replaceable higher-fidelity option and
      landmark-level JCS validation is still pending.</p>
      </html>"));
    end AnkleComplex;
  
    model Hip
      "Reduced serial 3-DOF hip with optional explicit passive impedance"
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=3);
      parameter Modelica.Units.SI.Angle q_start[3]={0,0,0};
      parameter Boolean q_fixed[3]=fill(false,3)
        "Fix initial joint coordinates for verification/prescribed initial configurations";
      parameter Modelica.Units.SI.AngularVelocity w_start[3]=fill(0,3);
      parameter Boolean w_fixed[3]=fill(false,3)
        "Fix initial angular velocities only when explicitly requested";
      parameter Boolean isLeft=true
        "Side-aware signs for adduction and axial rotation";
      parameter Real kPassive[3](each unit="N.m/rad")={0,0,0}
        "Explicit passive joint stiffness in generalized coordinates";
      parameter Real cPassive[3](each unit="N.m.s/rad")={0,0,0}
        "Explicit passive joint damping in generalized coordinates";
      parameter Modelica.Units.SI.Angle qNeutral[3]={0,0,0};

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a "Pelvis hip centre";
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b "Thigh proximal";

      output Modelica.Units.SI.Angle q[3];
      output Modelica.Units.SI.AngularVelocity w[3];
      output Real limitUtilization[3];
      output Integer limitingDOF;
      output Modelica.Units.SI.Torque passiveTorque[3];
      output Modelica.Units.SI.Power passivePower;

    protected
      // Library neutral axes: +x anterior, +y leftward, +z superior.
      Modelica.Mechanics.MultiBody.Joints.Revolute flexExt(
        n={0,-1,0}, useAxisFlange=true,
        phi(start=q_start[1], fixed=q_fixed[1]),
        w(start=w_start[1], fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute addAbd(
        n=if isLeft then {-1,0,0} else {1,0,0}, useAxisFlange=true,
        phi(start=q_start[2], fixed=q_fixed[2]),
        w(start=w_start[2], fixed=w_fixed[2]));
      Modelica.Mechanics.MultiBody.Joints.Revolute intExt(
        n=if isLeft then {0,0,-1} else {0,0,1}, useAxisFlange=true,
        phi(start=q_start[3], fixed=q_fixed[3]),
        w(start=w_start[3], fixed=w_fixed[3]));
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveFlex(
        c=kPassive[1],d=cPassive[1],phi_rel0=-qNeutral[1]);
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveAdd(
        c=kPassive[2],d=cPassive[2],phi_rel0=-qNeutral[2]);
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveAxial(
        c=kPassive[3],d=cPassive[3],phi_rel0=-qNeutral[3]);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=3, mobility=mobility);

    equation
      connect(frame_a, flexExt.frame_a);
      connect(flexExt.frame_b, addAbd.frame_a);
      connect(addAbd.frame_b, intExt.frame_a);
      connect(intExt.frame_b, frame_b);
      connect(flexExt.axis,passiveFlex.flange_a); connect(flexExt.support,passiveFlex.flange_b);
      connect(addAbd.axis,passiveAdd.flange_a); connect(addAbd.support,passiveAdd.flange_b);
      connect(intExt.axis,passiveAxial.flange_a); connect(intExt.support,passiveAxial.flange_b);

      q = {flexExt.phi, addAbd.phi, intExt.phi};
      w = {flexExt.w, addAbd.w, intExt.w};
      monitor.q = q;
      limitUtilization = monitor.utilization;
      limitingDOF = monitor.limitingDOF;
      passiveTorque=-kPassive.*(q-qNeutral)-cPassive.*w;
      passivePower=sum(passiveTorque.*w);

      annotation(Documentation(info="<html>
      <p>Clinical-axis mapping remains the corrected v0.6 convention. v0.9 adds optional
      explicit passive stiffness/damping with zero defaults, so legacy ideal-joint behavior is
      retained when kPassive=cPassive=0. Passive impedance is not muscle activation and is not
      a validated human tissue law until calibrated from an identified source.</p>
      </html>"));
    end Hip;

  
  end Joints;

  package Sensors
    extends Modelica.Icons.SensorsPackage;
  
    model JointLimitMonitor
      "ROM utilization and limiting-DOF monitor; no torque generation in v0.2"
      import SI = Modelica.Units.SI;
    
      parameter Integer n(min=1)=1;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=n);
    
      input SI.Angle q[n];
    
      output SI.Angle marginLower[n];
      output SI.Angle marginUpper[n];
      output SI.Angle distanceToLimit[n];
      output Real utilization[n];
      output Integer limitingDOF(start=1)
        "Legacy name: nearest raw-angle margin, NOT proof of an active causal constraint";
      output Boolean atLimit[n];
      output Boolean violated[n];
      parameter SI.Angle activationTolerance=1e-9;
      parameter SI.Angle tieTolerance=1e-12
        "Tolerance for reporting near-equal nearest margins; does not change strict argmin";
      output Boolean nearestMarginTie[n];
      output Integer nearestMarginCount;
    
    protected
      SI.Angle center[n];
      SI.Angle halfRange[n];
    
    equation
      assert(activationTolerance>=0 and tieTolerance>=0, "Monitor tolerances must be nonnegative.");
      nearestMarginCount = sum({if nearestMarginTie[i] then 1 else 0 for i in 1:n});
      for i in 1:n loop
        nearestMarginTie[i] = abs(distanceToLimit[i]-min(distanceToLimit))<=tieTolerance;
        assert(mobility.qMax[i] > mobility.qMin[i],
          "Each joint upper ROM bound must be greater than the lower bound.");
    
        marginLower[i] = q[i] - mobility.qMin[i];
        marginUpper[i] = mobility.qMax[i] - q[i];
        distanceToLimit[i] = min(marginLower[i], marginUpper[i]);
        center[i] = 0.5*(mobility.qMin[i] + mobility.qMax[i]);
        halfRange[i] = 0.5*(mobility.qMax[i] - mobility.qMin[i]);
        utilization[i] = abs(q[i] - center[i])/halfRange[i];
        atLimit[i] = distanceToLimit[i]<=activationTolerance;
        violated[i] = distanceToLimit[i]<-activationTolerance;
      end for;
    
    algorithm
      limitingDOF := 1;
      for i in 2:n loop
        if distanceToLimit[i] < distanceToLimit[limitingDOF] then
          limitingDOF := i;
        end if;
      end for;
    end JointLimitMonitor;
  
  end Sensors;

  package Contact
    "Distributed unilateral foot-ground contact and ground-wrench accounting"
    extends Modelica.Icons.Package;
  
    model ContactPoint
      "One unilateral compliant point contact with regularized Coulomb friction"
      import SI = Modelica.Units.SI;
    
      parameter SI.Position groundHeight=0
        "World z coordinate of horizontal contact plane";
      parameter Real kNormal(unit="N/m")=2e5
        "Penalty stiffness; computational contact parameter, not tissue stiffness";
      parameter Real cNormal(unit="N.s/m")=500
        "Penalty damping; computational contact parameter";
      parameter Real mu(min=0)=0.7
        "Regularized Coulomb friction coefficient";
      parameter SI.Velocity vSlip=0.01
        "Velocity scale for tanh friction regularization";
      parameter SI.Velocity vEps=1e-6
        "Regularization used in tangential direction normalization";
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_contact;
    
      output SI.Position rWorld[3];
      output SI.Velocity vWorld[3];
      output SI.Length penetration;
      output SI.Force normalForce;
      output SI.Force forceWorld[3];
      output Real frictionUtilization;
      output Boolean active;
    
    protected
      SI.Velocity penetrationRate;
      SI.Velocity vTangential;
      SI.Velocity vTangentialReg;
      SI.Force frictionMagnitude;
    
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition position(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsoluteVelocity velocity(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
    
      Modelica.Mechanics.MultiBody.Forces.WorldForce worldForce(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameB.world);
    
    equation
      assert(kNormal>0 and cNormal>=0 and mu>=0 and vSlip>0 and vEps>0,
        "Invalid contact stiffness/damping/friction regularization parameters.");
      connect(frame_contact, position.frame_a);
      connect(frame_contact, velocity.frame_a);
      connect(frame_contact, worldForce.frame_b);
    
      rWorld = position.r;
      vWorld = velocity.v;
    
      penetration = max(0, groundHeight - rWorld[3]);
      penetrationRate = if penetration > 0 then -vWorld[3] else 0;
    
      // Linear unilateral penalty law. The max() prevents tensile contact.
      normalForce =
        if penetration > 0 then
          max(0, kNormal*penetration + cNormal*penetrationRate)
        else 0;
    
      vTangential = sqrt(vWorld[1]^2 + vWorld[2]^2);
      vTangentialReg = sqrt(vTangential^2 + vEps^2);
      frictionMagnitude =
        mu*normalForce*Modelica.Math.tanh(vTangential/vSlip);
    
      forceWorld[1] = -frictionMagnitude*vWorld[1]/vTangentialReg;
      forceWorld[2] = -frictionMagnitude*vWorld[2]/vTangentialReg;
      forceWorld[3] = normalForce;
    
      worldForce.force = forceWorld;
    
      frictionUtilization =
        if normalForce > 1e-9 then
          sqrt(forceWorld[1]^2 + forceWorld[2]^2)/(mu*normalForce + 1e-12)
        else 0;
    
      active = normalForce > 0;
    
      annotation(Documentation(info="<html>
      <p>v0.3 deliberately uses a simple unilateral Kelvin-Voigt penalty normal
      law and smooth Coulomb friction. These are numerical contact laws used to
      establish force/moment routing and verification infrastructure. Their
      parameters must not be interpreted as anatomical plantar stiffness or a
      universal shoe-floor friction value.</p>
      <p>The applied force is resolved in the world frame and acts at the
      connected plantar frame.</p>
      </html>"));
    end ContactPoint;
  
    model GroundWrenchSensor
      "Aggregate distributed contact forces and free moments into a complete ground wrench"
      import SI = Modelica.Units.SI;
    
      parameter Integer nZones(min=1)=6;
      parameter SI.Position referencePoint[3]={0,0,0};
      parameter SI.Force fzEps=1e-6;
      parameter SI.Position contactPlaneHeight=0
        "World z of plane on which the wrench-equivalent COP is reported";
    
      input SI.Position rWorld[nZones,3];
      input SI.Force forceWorld[nZones,3];
      input SI.Torque freeMomentWorld[nZones,3];
    
      output SI.Force resultantForce[3];
      output SI.Torque resultantMoment[3]
        "Moment about referencePoint";
      output SI.Position cop[2]
        "COP x/y on the horizontal ground plane; zero if vertical load is negligible";
      output Boolean copValid "False when compressive resultant vertical load is too small";
      output SI.Torque freeMomentAtCOP "Residual vertical moment after moving wrench to COP";
      output SI.Torque yawFromShear;
      output SI.Torque yawFromFreeMoment;
      output SI.Torque yawTotal;
    
    equation
      // v0.7.3: scalar reduction equations avoid an OpenModelica 1.27.1
      // backend adjacency failure caused by aliased outputs of the old algorithm.
      // The wrench and reporting-plane definitions are unchanged.
      for j in 1:3 loop
        resultantForce[j] = sum(forceWorld[:,j]);
      end for;
      resultantMoment[1] = sum((rWorld[i,2]-referencePoint[2])*forceWorld[i,3]
        - (rWorld[i,3]-referencePoint[3])*forceWorld[i,2]
        + freeMomentWorld[i,1] for i in 1:nZones);
      resultantMoment[2] = sum((rWorld[i,3]-referencePoint[3])*forceWorld[i,1]
        - (rWorld[i,1]-referencePoint[1])*forceWorld[i,3]
        + freeMomentWorld[i,2] for i in 1:nZones);
      resultantMoment[3] = sum((rWorld[i,1]-referencePoint[1])*forceWorld[i,2]
        - (rWorld[i,2]-referencePoint[2])*forceWorld[i,1]
        + freeMomentWorld[i,3] for i in 1:nZones);
      yawFromShear = sum((rWorld[i,1]-referencePoint[1])*forceWorld[i,2]
        - (rWorld[i,2]-referencePoint[2])*forceWorld[i,1] for i in 1:nZones);
      yawFromFreeMoment = sum(freeMomentWorld[:,3]);
      yawTotal = yawFromShear + yawFromFreeMoment;
      copValid = resultantForce[3] > fzEps;
      if copValid then
        cop[1] = referencePoint[1]
          + (contactPlaneHeight-referencePoint[3])*resultantForce[1]/resultantForce[3]
          - resultantMoment[2]/resultantForce[3];
        cop[2] = referencePoint[2]
          + (contactPlaneHeight-referencePoint[3])*resultantForce[2]/resultantForce[3]
          + resultantMoment[1]/resultantForce[3];
        freeMomentAtCOP = resultantMoment[3]
          - (cop[1]-referencePoint[1])*resultantForce[2]
          + (cop[2]-referencePoint[2])*resultantForce[1];
      else
        cop[1] = 0;
        cop[2] = 0;
        freeMomentAtCOP = 0;
      end if;
    
      annotation(Documentation(info="<html>
      <p>v0.7 distinguishes the reporting-plane COP from the normal-load centroid.
      Reporting-point height is included in the wrench transformation. A zero
      stored COP when copValid=false is not a measured/support point.</p>
      <p>This component intentionally reports the complete resultant force and
      moment, and explicitly decomposes yaw into the shear-moment contribution
      plus any supplied free/torsional contact moment. Medial normal pressure by
      itself is therefore not treated as yaw torque.</p>
      </html>"));
    end GroundWrenchSensor;
  
    model PlantarContact
      "Six-zone unilateral plantar contact with complete ground-wrench reconstruction"
      import SI = Modelica.Units.SI;
    
      parameter Integer nZones=6;
      parameter SI.Position groundHeight=0;
      parameter Real kNormal(unit="N/m")=2e5;
      parameter Real cNormal(unit="N.s/m")=500;
      parameter Real mu(min=0)=0.7;
      parameter SI.Velocity vSlip=0.01;
      parameter Real torsionalFrictionFactor(min=0,max=1)=0
        "Fraction of residual local Coulomb budget, v0.7";
      parameter SI.Length patchRadius[nZones]=fill(0,nZones);
      parameter SI.AngularVelocity omegaTorsionSlip=0.05;
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a plantarFrames[nZones];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_torsion
        "Rigid foot frame receiving the optional pure yaw contact moment";
    
      output SI.Force zoneForceWorld[nZones,3];
      output SI.Force zoneNormalForce[nZones];
      output Real frictionUtilization[nZones];
      output Boolean zoneActive[nZones];
      output SI.Position zonePositionWorld[nZones,3];
    
      output SI.Force groundReactionForce[3];
      output SI.Torque groundMoment[3];
      output SI.Position cop[2];
      output Boolean copValid;
      output SI.Position normalPressureCentroid[2];
      output Boolean normalPressureCentroidValid;
      output SI.Torque freeMomentAtCOP;
      output SI.Torque yawFromShear;
      output SI.Torque yawFromFreeMoment;
      output SI.Torque yawTotal;
      output SI.Torque torsionalCapacity;
      output SI.Length torsionalEffectiveRadius;
      output Real torsionalUtilization;
    
    protected
      ContactPoint zone[nZones](
        each groundHeight=groundHeight,
        each kNormal=kNormal,
        each cNormal=cNormal,
        each mu=mu,
        each vSlip=vSlip);
    
      SI.Torque freeMomentWorld[nZones,3];
      GroundWrenchSensor wrench(nZones=nZones,contactPlaneHeight=groundHeight);
      TorsionalContactLaw torsion(
        nZones=nZones,
        torsionalFrictionFactor=torsionalFrictionFactor,
        omegaSlip=omegaTorsionSlip,mu=mu,patchRadius=patchRadius);
    
    equation
      connect(frame_torsion, torsion.frame_foot);
      torsion.rWorld = zonePositionWorld;
      torsion.normalForce = zoneNormalForce;
      torsion.tangentialForce = zoneForceWorld[:,1:2];
    
      for i in 1:nZones loop
        connect(plantarFrames[i], zone[i].frame_contact);
    
        zonePositionWorld[i,:] = zone[i].rWorld;
        zoneForceWorld[i,:] = zone[i].forceWorld;
        zoneNormalForce[i] = zone[i].normalForce;
        frictionUtilization[i] = zone[i].frictionUtilization;
        zoneActive[i] = zone[i].active;
    
        // The aggregate pure yaw moment is reported once to the wrench sensor.
        freeMomentWorld[i,:] = if i == 1 then {0,0,torsion.freeMoment} else {0,0,0};
      end for;
    
      wrench.rWorld = zonePositionWorld;
      wrench.forceWorld = zoneForceWorld;
      wrench.freeMomentWorld = freeMomentWorld;
    
      groundReactionForce = wrench.resultantForce;
      groundMoment = wrench.resultantMoment;
      cop = wrench.cop;
      copValid = wrench.copValid;
      freeMomentAtCOP = wrench.freeMomentAtCOP;
      normalPressureCentroid = torsion.normalCOP;
      normalPressureCentroidValid = torsion.normalCOPValid;
      yawFromShear = wrench.yawFromShear;
      yawFromFreeMoment = wrench.yawFromFreeMoment;
      yawTotal = wrench.yawTotal;
      torsionalCapacity = torsion.capacity;
      torsionalEffectiveRadius = torsion.effectiveRadius;
      torsionalUtilization = torsion.utilization;
    
      annotation(Documentation(info="<html><p>v0.7: six unilateral contact forces,
      a plane-aware wrench/COP sensor and optional residual-budget disk-patch spin.
      A normal-force centroid and a wrench-equivalent COP are both reported because
      penetration, shear and reporting-plane height can make them differ. The spin
      model no longer adds an independent whole-foot capacity on top of saturated
      shear. See docs/RELEASE_V0_7.md for scope and migration.</p></html>"));
    end PlantarContact;
  
    function torsionalCapacity
      "Derived torsional free-moment capacity from the current normal-load footprint"
      // LEGACY v0.5/v0.6 formula: retained for regression only; NOT used by v0.7 active contact.
      import SI = Modelica.Units.SI;
    
      input Integer nZones(min=1)=6;
      input SI.Position rWorld[nZones,3];
      input SI.Force normalForce[nZones];
      input Real torsionalFrictionFactor(min=0)=0
        "Dimensionless model coefficient; explicit assumption, not a human constant";
      input SI.Force fzEps=1e-9;
    
      output SI.Torque capacity;
      output SI.Length effectiveRadius;
      output SI.Position normalCOP[2];
    
    protected
      SI.Force totalNormal;
      Real secondMoment(unit="m2");
      Real weightedPosition[2](each unit="N.m") "First moment of compressive load";
    
    algorithm
      assert(fzEps>=0 and torsionalFrictionFactor>=0, "Nonnegative threshold/factor required.");
      totalNormal := 0;
      normalCOP := {0,0};
      weightedPosition := {0,0};
    
      for i in 1:nZones loop
        totalNormal := totalNormal + max(0, normalForce[i]);
        weightedPosition[1] := weightedPosition[1] + rWorld[i,1]*max(0, normalForce[i]);
        weightedPosition[2] := weightedPosition[2] + rWorld[i,2]*max(0, normalForce[i]);
      end for;
    
      if totalNormal > fzEps then
        normalCOP := weightedPosition/totalNormal;
        secondMoment := 0;
        for i in 1:nZones loop
          secondMoment := secondMoment
            + max(0, normalForce[i])
              *((rWorld[i,1]-normalCOP[1])^2
              + (rWorld[i,2]-normalCOP[2])^2)/totalNormal;
        end for;
        effectiveRadius := sqrt(max(0, secondMoment));
        capacity := torsionalFrictionFactor*totalNormal*effectiveRadius;
      else
        normalCOP := {0,0}; // Undefined COP: storage sentinel, not a support location.
        effectiveRadius := 0;
        capacity := 0;
      end if;
    
      annotation(Documentation(info="<html>
      <p><b>Project derivation, not a published constitutive law.</b> The current
      normal-load footprint is reduced to a load-weighted RMS radius about its
      normal-force COP:</p>
      <p>r_eff^2 = sum_i Fz_i ||r_i,xy-r_COP,xy||^2 / sum_i Fz_i.</p>
      <p>The diagnostic torsional capacity is then</p>
      <p>|Mz,free| &lt;= mu_t Fz r_eff.</p>
      <p>This construction is dimensionally consistent, becomes zero when contact
      collapses to a single point, increases with both normal load and support
      spread, and preserves the scientific distinction between COP migration and
      yaw-generating tangential/torsional contact. The factor mu_t is an explicit
      model parameter to be calibrated or swept; it is not identified as a human,
      shoe, or floor constant.</p>
      </html>"));
    end torsionalCapacity;
  
    model TorsionalContactLaw
      "Optional dissipative spin moment using residual local traction capacity (v0.7)"
      import SI = Modelica.Units.SI;
      parameter Integer nZones(min=1)=6;
      parameter Real torsionalFrictionFactor(min=0,max=1)=0
        "Fraction of residual local Coulomb budget, NOT an independent friction coefficient";
      parameter Real mu(min=0)=0.7;
      parameter SI.Length patchRadius[nZones]=fill(0,nZones)
        "Explicit uniform circular patch radii; zero means no subpatch spin";
      parameter SI.AngularVelocity omegaSlip=0.05;
      input SI.Position rWorld[nZones,3];
      input SI.Force normalForce[nZones];
      input SI.Force tangentialForce[nZones,2];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_foot;
      output SI.Torque freeMoment;
      output SI.Torque capacity;
      output SI.Torque zoneCapacity[nZones];
      output SI.Torque zoneFreeMoment[nZones];
      output SI.Length effectiveRadius "Capacity/mu/Fz; not a whole-foot RMS footprint radius";
      output SI.Position normalCOP[2];
      output Boolean normalCOPValid;
      output SI.AngularVelocity omegaZ;
      output Real utilization;
    protected
      SI.Force totalNormal;
      Modelica.Mechanics.MultiBody.Sensors.AbsoluteAngularVelocity angularVelocity(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Forces.WorldTorque worldTorque(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameB.world);
    equation
      assert(omegaSlip>0, "omegaSlip must be positive.");
      connect(frame_foot, angularVelocity.frame_a);
      connect(frame_foot, worldTorque.frame_b);
      (capacity,zoneCapacity) = residualSpinCapacity(nZones,normalForce,
        tangentialForce,mu,patchRadius,torsionalFrictionFactor);
      totalNormal = sum(normalForce);
      normalCOPValid = totalNormal>1e-9;
      normalCOP = if normalCOPValid then
        {sum(rWorld[:,1].*normalForce)/totalNormal,
         sum(rWorld[:,2].*normalForce)/totalNormal} else {0,0};
      effectiveRadius = if mu*totalNormal>1e-9 then capacity/(mu*totalNormal) else 0;
      omegaZ = angularVelocity.w[3];
      for i in 1:nZones loop
        zoneFreeMoment[i] = -zoneCapacity[i]*Modelica.Math.tanh(omegaZ/omegaSlip);
        for j in i+1:nZones loop
          assert(torsionalFrictionFactor<=0 or normalForce[i]<=0 or normalForce[j]<=0
            or sqrt((rWorld[i,1]-rWorld[j,1])^2+(rWorld[i,2]-rWorld[j,2])^2)
               >= patchRadius[i]+patchRadius[j],
            "Loaded spin subpatches overlap in the horizontal plane.");
        end for;
      end for;
      freeMoment = sum(zoneFreeMoment);
      worldTorque.torque = {0,0,freeMoment};
      utilization = if capacity>1e-12 then abs(freeMoment)/capacity else 0;
      annotation(Documentation(info="<html><p>v0.7 replaces the uncoupled whole-foot RMS
      envelope. Nonzero spin now requires explicitly declared patch radii and shares
      the existing shear budget. Default factor and radii are zero. This regularized
      sliding law has no static stick torque at zero angular speed. It is a reduced
      horizontal-plane contact assumption, not validated plantar/footwear mechanics.</p></html>"));
    end TorsionalContactLaw;
  
    function residualSpinCapacity
      "Conservative spin capacities of uniform circular subpatches sharing the Coulomb budget"
      import SI = Modelica.Units.SI;
      input Integer nZones(min=1);
      input SI.Force normalForce[nZones];
      input SI.Force tangentialForce[nZones,2];
      input Real mu(min=0);
      input SI.Length patchRadius[nZones];
      input Real reserveFraction(min=0,max=1)=1;
      output SI.Torque capacity;
      output SI.Torque zoneCapacity[nZones];
    protected
      SI.Force remaining;
    algorithm
      assert(mu>=0 and reserveFraction>=0 and reserveFraction<=1,
        "Invalid friction coefficient or spin reserve fraction.");
      capacity := 0;
      for i in 1:nZones loop
        assert(patchRadius[i]>=0, "Patch radii must be nonnegative.");
        remaining := max(0, mu*max(0,normalForce[i])
          - sqrt(tangentialForce[i,1]^2+tangentialForce[i,2]^2));
        zoneCapacity[i] := reserveFraction*(2.0/3.0)*patchRadius[i]*remaining;
        capacity := capacity + zoneCapacity[i];
      end for;
      annotation(Documentation(info="<html><p>New project derivation under explicit assumptions:
      disjoint uniform-pressure circular subpatches on a horizontal plane. The
      sufficient local inequality is |Ft_i| + |Mz_i|/(2*a_i/3) &lt;= mu*Fz_i.
      It follows by superposing constant translational traction and symmetric
      azimuthal traction and using the triangle inequality. This is conservative,
      not the exact combined friction limit surface or measured plantar mechanics.</p></html>"));
    end residualSpinCapacity;
  

    model AuditedPlantarContact
      "Six-zone plantar contact with regional support and energy-audit outputs"
      import SI = Modelica.Units.SI;
      extends PlantarContact(torsionalFrictionFactor=0,zone(each vEps=1e-9));
      output SI.Length penetration[nZones]={max(0,groundHeight-zonePositionWorld[i,3]) for i in 1:nZones};
      output SI.Velocity velocity[nZones,3]=der(zonePositionWorld);
      output SI.Energy storedEnergy=0.5*kNormal*sum(penetration.^2);
      output SI.Power normalLoss[nZones],frictionLoss[nZones];
      output SI.Power lossPower;
      output SI.Power powerToBody=sum(zoneForceWorld[i,:]*velocity[i,:] for i in 1:nZones);
      output SI.Power identityResidual=der(storedEnergy)+lossPower+powerToBody;
      output SI.Length loadedTangentialTravel[nZones](each start=0,each fixed=true);
      output SI.Force heelLoad=sum(zoneNormalForce[1:2]);
      output SI.Force midfootLoad=sum(zoneNormalForce[3:4]);
      output SI.Force forefootLoad=sum(zoneNormalForce[5:6]);
      output Boolean supportValid=sum(zoneNormalForce)>1;
      output Real heelShare=if supportValid then heelLoad/sum(zoneNormalForce) else 0;
      output Boolean broadSupport=supportValid and min({heelLoad,midfootLoad,forefootLoad})>0.1;
    equation
      for i in 1:nZones loop
        normalLoss[i]=(zoneNormalForce[i]-kNormal*penetration[i])*(if penetration[i]>0 then -velocity[i,3] else 0);
        frictionLoss[i]=-zoneForceWorld[i,1:2]*velocity[i,1:2];
        der(loadedTangentialTravel[i])=if zoneNormalForce[i]>0.1 then sqrt(sum(velocity[i,1:2].^2)) else 0;
      end for;
      lossPower=sum(normalLoss)+sum(frictionLoss);
      assert(lossPower>=-1e-7,"Audited plantar contact generated unexplained energy.");
      annotation(Documentation(info="<html><p>Audit wrapper around the six-zone plantar model. It exposes heel, midfoot and forefoot normal loads, a broad-support flag, loaded tangential travel, compliant contact storage and dissipative power. It is a numerical contact observer, not a plantar tissue-pressure model.</p></html>"));
    end AuditedPlantarContact;

  end Contact;

  package Assemblies
    extends Modelica.Icons.Package;
  
    model LowerBodyAssembly
      "First bilateral lower-body assembly; no ground contact yet"
      import SI = Modelica.Units.SI;
    
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter Boolean fixInitialJointCoordinates=false;
      parameter Boolean fixInitialJointVelocities=false;
      parameter Modelica.Units.SI.Angle leftHipStart[3]=zeros(3), rightHipStart[3]=zeros(3);
      parameter Modelica.Units.SI.Angle leftKneeStart=0, rightKneeStart=0;
      parameter Modelica.Units.SI.Angle leftAnkleStart[2]=zeros(2), rightAnkleStart[2]=zeros(2);
      parameter Modelica.Units.SI.Length footCOMAboveSole=0;
      parameter String footCOMOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE";
    
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftHipMobility(n=3)=hipMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightHipMobility(n=3)=hipMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftKneeMobility(n=1)=kneeMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightKneeMobility(n=1)=kneeMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftAnkleMobility(n=2)=ankleMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightAnkleMobility(n=2)=ankleMobility;
    
    
      parameter Boolean animation=true;
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisProximal;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b rightPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftFootReference
        "Rigid reference frame on left foot for pure contact moments";
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b rightFootReference
        "Rigid reference frame on right foot for pure contact moments";
    
      output SI.Mass representedMass
        "Mass of explicit lower-body segments; NOT profile.mass or a complete human";
      output Real leftAnkleLimitUtilization[2];
      output Real rightAnkleLimitUtilization[2];
      output Real leftKneeLimitUtilization;
      output Real rightKneeLimitUtilization;
      output Real leftHipLimitUtilization[3];
      output Real rightHipLimitUtilization[3];
    
      output SI.Angle leftQ[6] "Hip 1:3, knee 4, ankle 5:6; diagnostic only";
      output SI.Angle rightQ[6];
    
    protected
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties pelvisProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Pelvis);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
    
      ModelicaHumanBodyPArts.Segments.Pelvis pelvis(
        props=pelvisProps,
        hipCenterDistance=profile.hipCenterDistance,
        animation=animation);
    
      ModelicaHumanBodyPArts.Joints.Hip leftHip(mobility=leftHipMobility, isLeft=true,
        q_start=leftHipStart, q_fixed=fill(fixInitialJointCoordinates,3),
        w_fixed=fill(fixInitialJointVelocities,3));
      ModelicaHumanBodyPArts.Segments.Thigh leftThigh(props=thighProps, animation=animation);
      ModelicaHumanBodyPArts.Joints.Knee leftKnee(mobility=leftKneeMobility,
        phi_start=leftKneeStart, phi_fixed=fixInitialJointCoordinates, w_fixed=fixInitialJointVelocities);
      ModelicaHumanBodyPArts.Segments.Shank leftShank(props=shankProps, animation=animation);
      ModelicaHumanBodyPArts.Joints.AnkleComplex leftAnkle(mobility=leftAnkleMobility, isLeft=true,
        q_start=leftAnkleStart, q_fixed=fill(fixInitialJointCoordinates,2),
        w_fixed=fill(fixInitialJointVelocities,2));
      ModelicaHumanBodyPArts.Segments.Foot leftFoot(
        props=footProps,
        footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel,
        ankleHeight=profile.ankleHeight,
        comAboveSole=footCOMAboveSole, comOffsetSourceId=footCOMOffsetSourceId,
        animation=animation,
        isLeft=true);
    
      ModelicaHumanBodyPArts.Joints.Hip rightHip(mobility=rightHipMobility, isLeft=false,
        q_start=rightHipStart, q_fixed=fill(fixInitialJointCoordinates,3),
        w_fixed=fill(fixInitialJointVelocities,3));
      ModelicaHumanBodyPArts.Segments.Thigh rightThigh(props=thighProps, animation=animation);
      ModelicaHumanBodyPArts.Joints.Knee rightKnee(mobility=rightKneeMobility,
        phi_start=rightKneeStart, phi_fixed=fixInitialJointCoordinates, w_fixed=fixInitialJointVelocities);
      ModelicaHumanBodyPArts.Segments.Shank rightShank(props=shankProps, animation=animation);
      ModelicaHumanBodyPArts.Joints.AnkleComplex rightAnkle(mobility=rightAnkleMobility, isLeft=false,
        q_start=rightAnkleStart, q_fixed=fill(fixInitialJointCoordinates,2),
        w_fixed=fill(fixInitialJointVelocities,2));
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(
        props=footProps,
        footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel,
        ankleHeight=profile.ankleHeight,
        comAboveSole=footCOMAboveSole, comOffsetSourceId=footCOMOffsetSourceId,
        animation=animation,
        isLeft=false);
    
    equation
      leftQ = cat(1,leftHip.q,{leftKnee.q},leftAnkle.q);
      rightQ = cat(1,rightHip.q,{rightKnee.q},rightAnkle.q);
      representedMass = pelvisProps.mass + 2*(thighProps.mass+shankProps.mass+footProps.mass);
      connect(frame_pelvisProximal, pelvis.frame_proximal);
    
      connect(pelvis.frame_leftHip, leftHip.frame_a);
      connect(leftHip.frame_b, leftThigh.frame_proximal);
      connect(leftThigh.frame_distal, leftKnee.frame_a);
      connect(leftKnee.frame_b, leftShank.frame_proximal);
      connect(leftShank.frame_distal, leftAnkle.frame_a);
      connect(leftAnkle.frame_b, leftFoot.frame_ankle);
      connect(leftFoot.frame_ankle, leftFootReference);
    
      connect(pelvis.frame_rightHip, rightHip.frame_a);
      connect(rightHip.frame_b, rightThigh.frame_proximal);
      connect(rightThigh.frame_distal, rightKnee.frame_a);
      connect(rightKnee.frame_b, rightShank.frame_proximal);
      connect(rightShank.frame_distal, rightAnkle.frame_a);
      connect(rightAnkle.frame_b, rightFoot.frame_ankle);
      connect(rightFoot.frame_ankle, rightFootReference);
    
    
      for i in 1:6 loop
        connect(leftFoot.frame_plantar[i], leftPlantarFrames[i]);
        connect(rightFoot.frame_plantar[i], rightPlantarFrames[i]);
      end for;
    
      leftAnkleLimitUtilization = leftAnkle.limitUtilization;
      rightAnkleLimitUtilization = rightAnkle.limitUtilization;
      leftKneeLimitUtilization = leftKnee.limitUtilization;
      rightKneeLimitUtilization = rightKnee.limitUtilization;
      leftHipLimitUtilization = leftHip.limitUtilization;
      rightHipLimitUtilization = rightHip.limitUtilization;
    
      annotation(Documentation(info="<html>
      <p>v0.6 uses one neutral anatomical coordinate convention across pelvis, thigh,
      shank and foot. Side-aware hip/ankle axes and right-foot contact mirroring
      are applied before canonical limiting-joint studies are attempted.</p>
      </html>"));
    end LowerBodyAssembly;
  
    model LowerBodyGroundedAssembly
      "Lower body with two six-zone plantar contacts"
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter Boolean fixInitialJointCoordinates=false;
      parameter Boolean fixInitialJointVelocities=false;
      parameter Modelica.Units.SI.Angle leftHipStart[3]=zeros(3), rightHipStart[3]=zeros(3);
      parameter Modelica.Units.SI.Angle leftKneeStart=0, rightKneeStart=0;
      parameter Modelica.Units.SI.Angle leftAnkleStart[2]=zeros(2), rightAnkleStart[2]=zeros(2);
      parameter Modelica.Units.SI.Length footCOMAboveSole=0;
      parameter String footCOMOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE";
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftHipMobility(n=3)=hipMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightHipMobility(n=3)=hipMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftKneeMobility(n=1)=kneeMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightKneeMobility(n=1)=kneeMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile leftAnkleMobility(n=2)=ankleMobility;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rightAnkleMobility(n=2)=ankleMobility;
    
    
      parameter Modelica.Units.SI.Position groundHeight=0 "Horizontal world-z reporting/contact plane";
      parameter Real kNormal(unit="N/m")=2e5;
      parameter Real cNormal(unit="N.s/m")=500;
      parameter Real mu(min=0)=0.7;
      parameter Modelica.Units.SI.Velocity vSlip=0.01;
      parameter Real torsionalFrictionFactor(min=0,max=1)=0;
      parameter Modelica.Units.SI.AngularVelocity omegaTorsionSlip=0.05;
      parameter Modelica.Units.SI.Length patchRadius[6]=fill(0,6);
    
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisProximal;
    
      output Modelica.Units.SI.Force leftGRF[3];
      output Modelica.Units.SI.Force rightGRF[3];
      output Modelica.Units.SI.Torque leftGroundMoment[3];
      output Modelica.Units.SI.Torque rightGroundMoment[3];
      output Modelica.Units.SI.Position leftCOP[2];
      output Modelica.Units.SI.Position rightCOP[2];
      output Boolean leftCOPValid;
      output Boolean rightCOPValid;
      output Modelica.Units.SI.Torque leftTorsionalCapacity;
      output Modelica.Units.SI.Torque rightTorsionalCapacity;
      output Real leftTorsionalUtilization;
      output Real rightTorsionalUtilization;
    
      output Modelica.Units.SI.Angle leftQ[6],rightQ[6];
      output Modelica.Units.SI.Mass representedMass;
      output Modelica.Units.SI.Position leftZonePosition[6,3],rightZonePosition[6,3];
      output Modelica.Units.SI.Force leftZoneForce[6,3],rightZoneForce[6,3];
    
    protected
      LowerBodyAssembly body(
        profile=profile,
        fixInitialJointCoordinates=fixInitialJointCoordinates,
        fixInitialJointVelocities=fixInitialJointVelocities,
        leftHipStart=leftHipStart, rightHipStart=rightHipStart,
        leftKneeStart=leftKneeStart, rightKneeStart=rightKneeStart,
        leftAnkleStart=leftAnkleStart, rightAnkleStart=rightAnkleStart,
        footCOMAboveSole=footCOMAboveSole, footCOMOffsetSourceId=footCOMOffsetSourceId,
        hipMobility=hipMobility,
        kneeMobility=kneeMobility,
        ankleMobility=ankleMobility,
        leftHipMobility=leftHipMobility,rightHipMobility=rightHipMobility,
        leftKneeMobility=leftKneeMobility,rightKneeMobility=rightKneeMobility,
        leftAnkleMobility=leftAnkleMobility,rightAnkleMobility=rightAnkleMobility);
    
      ModelicaHumanBodyPArts.Contact.PlantarContact leftContact(
        groundHeight=groundHeight,
        kNormal=kNormal, cNormal=cNormal, mu=mu, vSlip=vSlip,
        torsionalFrictionFactor=torsionalFrictionFactor,
        omegaTorsionSlip=omegaTorsionSlip,patchRadius=patchRadius);
      ModelicaHumanBodyPArts.Contact.PlantarContact rightContact(
        groundHeight=groundHeight,
        kNormal=kNormal, cNormal=cNormal, mu=mu, vSlip=vSlip,
        torsionalFrictionFactor=torsionalFrictionFactor,
        omegaTorsionSlip=omegaTorsionSlip,patchRadius=patchRadius);
    
    equation
      leftQ=body.leftQ; rightQ=body.rightQ;
      representedMass=body.representedMass;
      leftZonePosition=leftContact.zonePositionWorld;
      rightZonePosition=rightContact.zonePositionWorld;
      leftZoneForce=leftContact.zoneForceWorld;
      rightZoneForce=rightContact.zoneForceWorld;
      connect(frame_pelvisProximal, body.frame_pelvisProximal);
      connect(body.leftFootReference, leftContact.frame_torsion);
      connect(body.rightFootReference, rightContact.frame_torsion);
    
      for i in 1:6 loop
        connect(body.leftPlantarFrames[i], leftContact.plantarFrames[i]);
        connect(body.rightPlantarFrames[i], rightContact.plantarFrames[i]);
      end for;
    
      leftGRF = leftContact.groundReactionForce;
      rightGRF = rightContact.groundReactionForce;
      leftGroundMoment = leftContact.groundMoment;
      rightGroundMoment = rightContact.groundMoment;
      leftCOP = leftContact.cop;
      leftCOPValid = leftContact.copValid;
      rightCOPValid = rightContact.copValid;
      rightCOP = rightContact.cop;
      leftTorsionalCapacity = leftContact.torsionalCapacity;
      rightTorsionalCapacity = rightContact.torsionalCapacity;
      leftTorsionalUtilization = leftContact.torsionalUtilization;
      rightTorsionalUtilization = rightContact.torsionalUtilization;
    end LowerBodyGroundedAssembly;
  
  end Assemblies;

  package Examples
    extends Modelica.Icons.ExamplesPackage;
  
    model LowerBodyFreeChainDemo
      "Numerical smoke test only; parameter values are not validation data"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity,
        n={0,0,-1});
    
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75,
        mass=75,
        sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26,
        footWidth=0.095,
        ankleFromHeel=0.07,
        ankleHeight=0.08,
        shankLength=0.43,
        thighLength=0.44,
        pelvisLength=0.18,
        hipCenterDistance=0.20);
    
      // Example-only ROM values. They must not be interpreted as universal
      // anatomical constants and will be replaced by the dedicated ROM dataset.
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,
        qMin={-0.35,-0.52,-0.79},
        qMax={2.09,0.79,0.79},
        sourceId="DEMO_ONLY");
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,
        qMin={0},
        qMax={2.36},
        sourceId="DEMO_ONLY");
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,
        qMin={-0.87,-0.26},
        qMax={0.35,0.61},
        sourceId="DEMO_ONLY");
    
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedPelvis(r={0,0,1.0});
      ModelicaHumanBodyPArts.Assemblies.LowerBodyAssembly body(
        profile=profile,
        hipMobility=hipROM,
        kneeMobility=kneeROM,
        ankleMobility=ankleROM);
    
    equation
      connect(fixedPelvis.frame_b, body.frame_pelvisProximal);
    
      annotation(
        experiment(StartTime=0, StopTime=1.0, Tolerance=1e-6, Interval=0.002),
        Documentation(info="<html>
        <p>This model is intended only to smoke-test translation/assembly in a
        Modelica compiler. The ROM numbers are examples, not source-validated
        human constants.</p>
        </html>"));
    end LowerBodyFreeChainDemo;
  
    model LowerBodyRoaasMeanDemo
      "Lower-body smoke test using one source-traceable passive ROM profile"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity,
        n={0,0,-1});
    
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75,
        mass=75,
        sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26,
        footWidth=0.095,
        ankleFromHeel=0.07,
        ankleHeight=0.08,
        shankLength=0.43,
        thighLength=0.44,
        pelvisLength=0.18,
        hipCenterDistance=0.20);
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3) =
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.hipMean();
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1) =
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.kneeMean();
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2) =
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.ankleMean();
    
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedPelvis(r={0,0,1.0});
      ModelicaHumanBodyPArts.Assemblies.LowerBodyAssembly body(
        profile=profile,
        hipMobility=hipROM,
        kneeMobility=kneeROM,
        ankleMobility=ankleROM,
        rightHipMobility=ModelicaHumanBodyPArts.Data.RoaasAndersson1982.hipMean(false),
        rightKneeMobility=ModelicaHumanBodyPArts.Data.RoaasAndersson1982.kneeMean(false),
        rightAnkleMobility=ModelicaHumanBodyPArts.Data.RoaasAndersson1982.ankleMean(false));
    
    equation
      connect(fixedPelvis.frame_b, body.frame_pelvisProximal);
    
      annotation(
        experiment(StartTime=0, StopTime=1.0, Tolerance=1e-6, Interval=0.002),
        Documentation(info="<html>
        <p>Only the ROM bounds are source-traceable here. The example geometry
        values remain smoke-test inputs and are not a validated anthropometric
        subject.</p>
        </html>"));
    end LowerBodyRoaasMeanDemo;
  
  end Examples;

  package Tests
    extends Modelica.Icons.ExamplesPackage;
  
    model NeutralStanceGeometryTest
      "Coordinate regression: neutral leg/foot geometry, side mirroring, hip-flexion sign"
      import SI = Modelica.Units.SI;
    
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity);
    
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75,
        mass=75,
        sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26,
        footWidth=0.095,
        ankleFromHeel=0.07,
        ankleHeight=0.08,
        shankLength=0.43,
        thighLength=0.44,
        pelvisLength=0.18,
        hipCenterDistance=0.20);
    
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3, qMin={-1,-1,-1}, qMax={2,1,1}, sourceId="TEST_ONLY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1, qMin={-0.2}, qMax={2.8}, sourceId="TEST_ONLY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2, qMin={-1,-1}, qMax={1,1}, sourceId="TEST_ONLY");
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      parameter SI.Angle hipFlex = Modelica.Units.Conversions.from_deg(10);
    
      // Neutral left leg: every initial joint coordinate is fixed at zero only for this regression test.
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedNeutralHip(r={0,0,1.0});
      ModelicaHumanBodyPArts.Joints.Hip neutralHip(
        mobility=hipROM, q_start={0,0,0}, q_fixed={true,true,true}, w_fixed={true,true,true}, isLeft=true);
      ModelicaHumanBodyPArts.Segments.Thigh neutralThigh(props=thighProps, animation=false);
      ModelicaHumanBodyPArts.Joints.Knee neutralKnee(
        mobility=kneeROM, phi_start=0, phi_fixed=true, w_fixed=true);
      ModelicaHumanBodyPArts.Segments.Shank neutralShank(props=shankProps, animation=false);
      ModelicaHumanBodyPArts.Joints.AnkleComplex neutralAnkle(
        mobility=ankleROM, q_start={0,0}, q_fixed={true,true}, w_fixed={true,true}, isLeft=true);
      ModelicaHumanBodyPArts.Segments.Foot neutralFoot(
        props=footProps, footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel, ankleHeight=profile.ankleHeight,
        animation=false, isLeft=true);
    
      // Positive hip-flexion chain.
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedFlexHip(r={0,0,1.0});
      ModelicaHumanBodyPArts.Joints.Hip flexedHip(
        mobility=hipROM, q_start={hipFlex,0,0}, q_fixed={true,true,true}, w_fixed={true,true,true}, isLeft=
        true);
      ModelicaHumanBodyPArts.Segments.Thigh flexedThigh(props=thighProps, animation=false);
    
      // Isolated right foot to verify medial/lateral mirroring.
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedRightAnkle(r={0,-0.20,0.20});
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(
        props=footProps, footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel, ankleHeight=profile.ankleHeight,
        animation=false, isLeft=false);
    
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition neutralKneePos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition neutralAnklePos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition heelPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition forefootPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition flexKneePos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition leftMedialPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition leftLateralPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition rightMedialPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition rightLateralPos(
        resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
    
      output Real observedKneeZ=neutralKneePos.r[3];
      output Real observedAnkleZ=neutralAnklePos.r[3];
      output Real observedHeelZ=heelPos.r[3];
      output Real observedFlexX=flexKneePos.r[1];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(fixedNeutralHip.frame_b, neutralHip.frame_a);
      connect(neutralHip.frame_b, neutralThigh.frame_proximal);
      connect(neutralThigh.frame_distal, neutralKnee.frame_a);
      connect(neutralKnee.frame_b, neutralShank.frame_proximal);
      connect(neutralShank.frame_distal, neutralAnkle.frame_a);
      connect(neutralAnkle.frame_b, neutralFoot.frame_ankle);
    
      connect(neutralThigh.frame_distal, neutralKneePos.frame_a);
      connect(neutralFoot.frame_ankle, neutralAnklePos.frame_a);
      connect(neutralFoot.frame_plantar[1], heelPos.frame_a);
      connect(neutralFoot.frame_plantar[5], forefootPos.frame_a);
      connect(neutralFoot.frame_plantar[1], leftMedialPos.frame_a);
      connect(neutralFoot.frame_plantar[2], leftLateralPos.frame_a);
    
      connect(fixedFlexHip.frame_b, flexedHip.frame_a);
      connect(flexedHip.frame_b, flexedThigh.frame_proximal);
      connect(flexedThigh.frame_distal, flexKneePos.frame_a);
    
      connect(fixedRightAnkle.frame_b, rightFoot.frame_ankle);
      connect(rightFoot.frame_plantar[1], rightMedialPos.frame_a);
      connect(rightFoot.frame_plantar[2], rightLateralPos.frame_a);
    
    initial equation
      assert(neutralKneePos.r[3] < fixedNeutralHip.r[3],
        "Neutral stance failed: knee must be inferior to hip.");
      assert(heelPos.r[3] < neutralAnklePos.r[3],
        "Neutral stance failed: plantar/heel point must be inferior to ankle.");
      assert(forefootPos.r[1] > heelPos.r[1],
        "Neutral stance failed: forefoot/toe direction must be anterior to heel.");
      assert(flexKneePos.r[1] > fixedFlexHip.r[1],
        "Hip-axis mapping failed: positive hip flexion must move knee anteriorly.");
      assert(leftMedialPos.r[2] < leftLateralPos.r[2],
        "Left-foot medial/lateral zone order failed.");
      assert(rightMedialPos.r[2] > rightLateralPos.r[2],
        "Right-foot medial/lateral zone mirror failed.");
    
    
    algorithm
      when time>=verificationTime then
        assert(neutralKneePos.r[3] < fixedNeutralHip.r[3],
        "Neutral stance failed: knee must be inferior to hip.");
        assert(heelPos.r[3] < neutralAnklePos.r[3],
        "Neutral stance failed: plantar/heel point must be inferior to ankle.");
        assert(forefootPos.r[1] > heelPos.r[1],
        "Neutral stance failed: forefoot/toe direction must be anterior to heel.");
        assert(flexKneePos.r[1] > fixedFlexHip.r[1],
        "Hip-axis mapping failed: positive hip flexion must move knee anteriorly.");
        assert(leftMedialPos.r[2] < leftLateralPos.r[2],
        "Left-foot medial/lateral zone order failed.");
        assert(rightMedialPos.r[2] > rightLateralPos.r[2],
        "Right-foot medial/lateral zone mirror failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0, StopTime=0.01, Tolerance=1e-8));
    end NeutralStanceGeometryTest;
  
    model HipAxisGeometryTest
      "Bilateral individual hip axes and combined serial order, using an off-axis marker"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter Real qCase[8,3]={{0.20000000000000001,0,0},{0,0.14999999999999999,0},{0,0,0.25},
        {0.20000000000000001,0.14999999999999999,0.25},{0.20000000000000001,0,0},{0,0.14999999999999999,0},
        {0,0,0.25},{0.20000000000000001,0.14999999999999999,0.25}};
      parameter Boolean sides[8]={true,true,true,true,false,false,false,false};
      parameter Real expectedKnee[8,3]={{0.087414505549826937,0,-0.43122929425014633},{0,
        -0.065752778288383662,-0.43505927429185859},{0,0,-0.44},{0.086432934879748527,-0.065752778288383662,
        -0.4263870541133159},{0.087414505549826937,0,-0.43122929425014633},{0,0.065752778288383662,
        -0.43505927429185859},{0,0,-0.44},{0.086432934879748527,0.065752778288383662,-0.4263870541133159}};
      parameter Real expectedMarker[8,3]={{0.18542116333395109,0,-0.41136236117064018},{0.10000000000000001,
        -0.065752778288383662,-0.43505927429185859},{0.096891242171064484,-0.024740395925452296,-0.44},
        {0.18065829099942585,-0.090215366236157585,-0.4035142743299705},{0.18542116333395109,0,
        -0.41136236117064018},{0.10000000000000001,0.065752778288383662,-0.43505927429185859},
        {0.096891242171064484,0.024740395925452296,-0.44},{0.18065829099942585,0.090215366236157585,
        -0.4035142743299705}};
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor[8](each r={0,0,1},each animation=false);
      ModelicaHumanBodyPArts.Joints.Hip hip[8](each mobility=hipROM,q_start=qCase,
        each q_fixed={true,true,true},each w_fixed={true,true,true},isLeft=sides);
      ModelicaHumanBodyPArts.Segments.Thigh thigh[8](each props=thighProps,each animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation marker[8](each r={0.1,0,-0.44},each animation=
        false);
      output Real observedKnee[8,3];
      output Real observedMarker[8,3];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      for i in 1:8 loop
        connect(anchor[i].frame_b,hip[i].frame_a);
        connect(hip[i].frame_b,thigh[i].frame_proximal);
        connect(hip[i].frame_b,marker[i].frame_a);
        observedKnee[i,:]=thigh[i].frame_distal.r_0-anchor[i].r;
        observedMarker[i,:]=marker[i].frame_b.r_0-anchor[i].r;
      end for;
    initial equation
      assert(max(abs(observedKnee-expectedKnee))<1e-8,"Hip endpoint geometry failed.");
      assert(max(abs(observedMarker-expectedMarker))<1e-8,"Hip axial/combined-order marker failed.");
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(observedKnee-expectedKnee))<1e-8,"Hip endpoint geometry failed.");
        assert(max(abs(observedMarker-expectedMarker))<1e-8,"Hip axial/combined-order marker failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end HipAxisGeometryTest;
  
    model KneeAxisGeometryTest
      "Positive knee flexion sends the distal ankle posteriorly in the declared frame"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,
        ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      ModelicaHumanBodyPArts.Joints.Knee knee(mobility=kneeROM,phi_start=0.2,phi_fixed=true,w_fixed=true);
      ModelicaHumanBodyPArts.Segments.Shank shank(props=shankProps,animation=false);
      output Real observedX=shank.frame_distal.r_0[1];
      output Real observedZ=shank.frame_distal.r_0[3];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(world.frame_b,knee.frame_a);
      connect(knee.frame_b,shank.frame_proximal);
    initial equation
      assert(abs(observedX+0.43*sin(0.2))<1e-8 and abs(observedZ+0.43*cos(0.2))<1e-8,
        "Knee flexion direction/geometry failed.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(observedX+0.43*sin(0.2))<1e-8 and abs(observedZ+0.43*cos(0.2))<1e-8,
        "Knee flexion direction/geometry failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end KneeAxisGeometryTest;
  
    model AnkleAxisGeometryTest
      "Nonzero bilateral dorsiflexion/inversion and serial-order geometry; no landmark validation"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
    
      parameter Real qCase[6,2]={{0.20000000000000001,0},{0,0.14999999999999999},{0.20000000000000001,
        0.14999999999999999},{0.20000000000000001,0},{0,0.14999999999999999},{0.20000000000000001,
        0.14999999999999999}};
      parameter Boolean sides[6]={true,true,true,false,false,false};
      parameter Real expectedToe[6,3]={{0.20210619625344078,0,-0.040658153376237696},{0.19,
        -0.011955050597887937,-0.079101686234883381},{0.20192772885888108,-0.011955050597887937,
        -0.039777746078632173},{0.20210619625344078,0,-0.040658153376237696},{0.19,0.011955050597887937,
        -0.079101686234883381},{0.20192772885888108,0.011955050597887937,-0.039777746078632173}};
      parameter Real expectedMedial[6,3]={{0.11292013766988783,-0.02375,-0.058737062478588273},
        {0.099000000000000005,-0.035438363698868942,-0.075552530588635397},{0.11203656189820052,
        -0.035438363698868942,-0.054378246352538566},{0.11292013766988783,0.02375,-0.058737062478588273},
        {0.099000000000000005,0.035438363698868942,-0.075552530588635397},{0.11203656189820052,
        0.035438363698868942,-0.054378246352538566}};
      parameter Real expectedLateral[6,3]={{0.11292013766988783,0.02375,-0.058737062478588273},
        {0.099000000000000005,0.011528262503093066,-0.082650841881131365},{0.11344677865245571,
        0.011528262503093066,-0.061335064009426919},{0.11292013766988783,-0.02375,-0.058737062478588273},
        {0.099000000000000005,-0.011528262503093066,-0.082650841881131365},{0.11344677865245571,
        -0.011528262503093066,-0.061335064009426919}};
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor[6](each r={0,0,0.2},each animation=false);
      ModelicaHumanBodyPArts.Joints.AnkleComplex ankle[6](each mobility=ankleROM,
        q_start=qCase,each q_fixed={true,true},each w_fixed={true,true},isLeft=sides);
      ModelicaHumanBodyPArts.Segments.Foot foot[6](each props=footProps,each footWidth=0.095,
        each ankleFromHeel=0.07,each ankleHeight=0.08,each animation=false,isLeft=sides);
      output Real observedToe[6,3];
      output Real observedMedial[6,3];
      output Real observedLateral[6,3];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      for i in 1:6 loop
        connect(anchor[i].frame_b,ankle[i].frame_a);
        connect(ankle[i].frame_b,foot[i].frame_ankle);
        observedToe[i,:]=foot[i].frame_toe.r_0-anchor[i].r;
        observedMedial[i,:]=foot[i].frame_medial.r_0-anchor[i].r;
        observedLateral[i,:]=foot[i].frame_lateral.r_0-anchor[i].r;
      end for;
    initial equation
      assert(max(abs(observedToe-expectedToe))<1e-8,"Ankle toe geometry/rotation order failed.");
      assert(max(abs(observedMedial-expectedMedial))<1e-8,"Ankle medial geometry failed.");
      assert(max(abs(observedLateral-expectedLateral))<1e-8,"Ankle lateral geometry failed.");
      assert(observedToe[1,3]>-0.08 and observedToe[4,3]>-0.08,"Positive dorsiflexion must raise toe.");
      assert(observedMedial[2,3]>observedLateral[2,3] and observedMedial[5,3]>observedLateral[5,3],
        "Positive inversion must raise medial border on both sides.");
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(observedToe-expectedToe))<1e-8,"Ankle toe geometry/rotation order failed.");
        assert(max(abs(observedMedial-expectedMedial))<1e-8,"Ankle medial geometry failed.");
        assert(max(abs(observedLateral-expectedLateral))<1e-8,"Ankle lateral geometry failed.");
        assert(observedToe[1,3]>-0.08 and observedToe[4,3]>-0.08,"Positive dorsiflexion must raise toe.");
        assert(observedMedial[2,3]>observedLateral[2,3] and observedMedial[5,3]>observedLateral[5,3],
        "Positive inversion must raise medial border on both sides.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end AnkleAxisGeometryTest;
  
    model ContactPointCompressionTest
      "Synthetic fixed-point test of the v0.3 unilateral normal contact law"
      inner Modelica.Mechanics.MultiBody.World world(n={0,0,-1});
    
      parameter Real k(unit="N/m")=100000;
      parameter Modelica.Units.SI.Length delta=0.001;
    
      Modelica.Mechanics.MultiBody.Parts.Fixed fixedPoint(r={0,0,-delta});
      ModelicaHumanBodyPArts.Contact.ContactPoint contact(
        kNormal=k,
        cNormal=0,
        mu=0);
    
      output Real observedForce=contact.normalForce;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    initial equation
      assert(abs(contact.normalForce - k*delta) < 1e-6,
        "Static compression contact-force check failed.");
    
    equation
      connect(fixedPoint.frame_b, contact.frame_contact);
    
    
    algorithm
      when time>=verificationTime then
        assert(abs(contact.normalForce - k*delta) < 1e-6,
        "Static compression contact-force check failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0, StopTime=0.01));
    end ContactPointCompressionTest;
  
    model ContactPointSeparationTest
      "No attractive contact force above the plane or at exact zero penetration"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
    
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor[2](r={{0,0,0.31},{0,0,0.30}},each animation=false);
      ModelicaHumanBodyPArts.Contact.ContactPoint contact[2](each groundHeight=0.3);
      output Real observedForce[2]={contact[1].normalForce,contact[2].normalForce};
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      for i in 1:2 loop
        connect(anchor[i].frame_b,contact[i].frame_contact);
        assert(contact[i].normalForce==0 and not contact[i].active,
        "Separated/touch-only contact must carry no load.");
      end for;
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(observedForce))<1e-12,"Separated force nonzero at check event.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end ContactPointSeparationTest;
  
    model GroundWrenchCOPTest
      "Analytic COP / force-moment balance check"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor w(nZones=3);
    
      output Real observedFz=w.resultantForce[3];
      output Real observedMy=w.resultantMoment[2];
      output Real observedCOPx=w.cop[1];
      output Real observedCOPy=w.cop[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      w.rWorld = {
        {-0.10,0,0},
        { 0.00,0,0},
        { 0.10,0,0}};
    
      w.forceWorld = {
        {0,0,200},
        {0,0,300},
        {0,0,500}};
    
      w.freeMomentWorld = fill(0,3,3);
    
    initial equation
      assert(abs(w.resultantForce[3] - 1000) < 1e-10,
        "Ground reaction vertical-force sum failed.");
      assert(abs(w.resultantMoment[2] + 30) < 1e-10,
        "Ground moment My check failed.");
      assert(abs(w.cop[1] - 0.03) < 1e-10,
        "COP x check failed.");
      assert(abs(w.cop[2]) < 1e-10,
        "COP y check failed.");
    
    
    algorithm
      when time>=verificationTime then
        assert(abs(w.resultantForce[3] - 1000) < 1e-10,
        "Ground reaction vertical-force sum failed.");
        assert(abs(w.resultantMoment[2] + 30) < 1e-10,
        "Ground moment My check failed.");
        assert(abs(w.cop[1] - 0.03) < 1e-10,
        "COP x check failed.");
        assert(abs(w.cop[2]) < 1e-10,
        "COP y check failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0, StopTime=0.01));
    end GroundWrenchCOPTest;
  
    model GroundWrenchCOPReferencePointTest
      "Analytic test that COP is reported in world coordinates for a nonzero reference point"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor wrench(
        nZones=1,
        referencePoint={1.0,2.0,0.0});
    
      output Real observedX=wrench.cop[1];
      output Real observedY=wrench.cop[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      wrench.rWorld = [1.20, 1.90, 0.0];
      wrench.forceWorld = [0.0, 0.0, 100.0];
      wrench.freeMomentWorld = [0.0, 0.0, 0.0];
    
      assert(abs(wrench.cop[1] - 1.20) < 1e-10,
        "COP x must include reference-point offset.");
      assert(abs(wrench.cop[2] - 1.90) < 1e-10,
        "COP y must include reference-point offset.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(wrench.cop[1] - 1.20) < 1e-10,
        "COP x must include reference-point offset.");
        assert(abs(wrench.cop[2] - 1.90) < 1e-10,
        "COP y must include reference-point offset.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end GroundWrenchCOPReferencePointTest;
  
    model GroundWrenchPlaneHeightTest
      "Oblique loading must give the same physical COP at different wrench reference heights"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor sensor(
        nZones=1,referencePoint={0.3,-0.2,0.4},contactPlaneHeight=0);
      output Real observedX=sensor.cop[1];
      output Real observedY=sensor.cop[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      sensor.rWorld=[0.02,-0.03,0];
      sensor.forceWorld=[60,-30,600];
      sensor.freeMomentWorld=zeros(1,3);
      assert(sensor.copValid and abs(sensor.cop[1]-0.02)<1e-10 and
        abs(sensor.cop[2]+0.03)<1e-10, "Reporting-height COP regression failed.");
    
    algorithm
      when time>=verificationTime then
        assert(sensor.copValid and abs(sensor.cop[1]-0.02)<1e-10 and
        abs(sensor.cop[2]+0.03)<1e-10, "Reporting-height COP regression failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-8));
    end GroundWrenchPlaneHeightTest;
  
    model GroundWrenchElevatedPlaneTest
      "COP invariance across horizontal-plane/reporting-point heights under oblique load"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor a(nZones=1,referencePoint={0,0,0},
        contactPlaneHeight=0.3);
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor b(nZones=1,referencePoint={0.7,-0.4,0.8},
        contactPlaneHeight=0.3);
      output Real observedA[2]=a.cop;
      output Real observedB[2]=b.cop;
      output Real observedResidualYaw=a.freeMomentAtCOP;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      a.rWorld=[0.1,-0.2,0.3]; a.forceWorld=[40,-20,200]; a.freeMomentWorld=[0,0,3];
      b.rWorld=a.rWorld; b.forceWorld=a.forceWorld; b.freeMomentWorld=a.freeMomentWorld;
      assert(a.copValid and b.copValid and max(abs(a.cop-{0.1,-0.2}))<1e-10,
        "Elevated-plane COP reference failed.");
      assert(max(abs(a.cop-b.cop))<1e-10 and abs(a.freeMomentAtCOP-3)<1e-10,
        "Wrench relocation/residual yaw failed.");
    
    algorithm
      when time>=verificationTime then
        assert(a.copValid and b.copValid and max(abs(a.cop-{0.1,-0.2}))<1e-10,
        "Elevated-plane COP reference failed.");
        assert(max(abs(a.cop-b.cop))<1e-10 and abs(a.freeMomentAtCOP-3)<1e-10,
        "Wrench relocation/residual yaw failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end GroundWrenchElevatedPlaneTest;
  
    model GroundWrenchZeroLoadTest
      "No COP is valid under zero, subthreshold, or negative resultant normal load"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor w[3](each nZones=1,each fzEps=1e-6);
      parameter Real forces[3]={0,1e-9,-10};
      output Real observedValid[3];
      output Real observedCOP[3,2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      for i in 1:3 loop
        w[i].rWorld=[1,2,0]; w[i].forceWorld=[2,3,forces[i]]; w[i].freeMomentWorld=[0,0,1];
        observedValid[i]=if w[i].copValid then 1 else 0;
        observedCOP[i,:]=w[i].cop;
        assert(not w[i].copValid and max(abs(w[i].cop))==0 and w[i].freeMomentAtCOP==0,
          "Undefined COP validity/sentinel failure.");
      end for;
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(observedValid))==0 and max(abs(observedCOP))==0,
        "No-load sentinel/validity failed at check event.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end GroundWrenchZeroLoadTest;
  
    model GroundWrenchYawSeparationTest
      "Demonstrate that asymmetric normal pressure is not itself yaw torque"
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor pressureOnly(nZones=2);
      ModelicaHumanBodyPArts.Contact.GroundWrenchSensor shearCouple(nZones=2);
    
      output Real observedPressureYaw=pressureOnly.yawTotal;
      output Real observedRoll=pressureOnly.resultantMoment[1];
      output Real observedShearYaw=shearCouple.yawTotal;
      output Real observedNetShear=shearCouple.resultantForce[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      // Medial/lateral normal-force asymmetry: roll moment, zero yaw.
      pressureOnly.rWorld = {
        {0,-0.05,0},
        {0, 0.05,0}};
      pressureOnly.forceWorld = {
        {0,0,600},
        {0,0,400}};
      pressureOnly.freeMomentWorld = fill(0,2,3);
    
      // Equal/opposite tangential forces at separated x positions:
      // zero net Fy, nonzero yaw moment.
      shearCouple.rWorld = {
        { 0.10,0,0},
        {-0.10,0,0}};
      shearCouple.forceWorld = {
        {0, 50,500},
        {0,-50,500}};
      shearCouple.freeMomentWorld = fill(0,2,3);
    
    initial equation
      assert(abs(pressureOnly.yawTotal) < 1e-10,
        "Normal-pressure asymmetry must not create yaw in this planar test.");
      assert(abs(pressureOnly.resultantMoment[1] + 10) < 1e-10,
        "Expected roll moment from medial/lateral pressure asymmetry.");
    
      assert(abs(shearCouple.resultantForce[2]) < 1e-10,
        "Tangential shear couple should have zero net Fy.");
      assert(abs(shearCouple.yawTotal - 10) < 1e-10,
        "Expected 10 N.m yaw moment from shear couple.");
    
    
    algorithm
      when time>=verificationTime then
        assert(abs(pressureOnly.yawTotal) < 1e-10,
        "Normal-pressure asymmetry must not create yaw in this planar test.");
        assert(abs(pressureOnly.resultantMoment[1] + 10) < 1e-10,
        "Expected roll moment from medial/lateral pressure asymmetry.");
        assert(abs(shearCouple.resultantForce[2]) < 1e-10,
        "Tangential shear couple should have zero net Fy.");
        assert(abs(shearCouple.yawTotal - 10) < 1e-10,
        "Expected 10 N.m yaw moment from shear couple.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0, StopTime=0.01));
    end GroundWrenchYawSeparationTest;
  
    model TorsionalCapacityTest
      "Analytic test of the project-derived torsional capacity function"
      import SI = Modelica.Units.SI;
    
      parameter Integer n=4;
      parameter SI.Position r[n,3] = {
        { 0.10, 0.05,0},
        { 0.10,-0.05,0},
        {-0.10, 0.05,0},
        {-0.10,-0.05,0}};
      parameter SI.Force fz[n] = {100,100,100,100};
      parameter Real muT=0.2;
      parameter SI.Length expectedRadius=sqrt(0.10^2 + 0.05^2);
      parameter SI.Torque expectedCapacity=muT*400*expectedRadius;
    
      SI.Torque cap;
      SI.Length rEff;
      SI.Position cop[2];
    
      output Real observedCapacity=cap;
      output Real observedRadius=rEff;
      output Real observedX=cop[1];
      output Real observedY=cop[2];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      (cap, rEff, cop) = ModelicaHumanBodyPArts.Contact.torsionalCapacity(n, r, fz, muT);
    
      assert(abs(cop[1]) < 1e-12 and abs(cop[2]) < 1e-12,
        "Symmetric load pattern must have zero normal-force COP.");
      assert(abs(rEff - expectedRadius) < 1e-10,
        "Effective radius does not match analytic symmetric result.");
      assert(abs(cap - expectedCapacity) < 1e-9,
        "Torsional capacity does not match analytic result.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(cop[1]) < 1e-12 and abs(cop[2]) < 1e-12,
        "Symmetric load pattern must have zero normal-force COP.");
        assert(abs(rEff - expectedRadius) < 1e-10,
        "Effective radius does not match analytic symmetric result.");
        assert(abs(cap - expectedCapacity) < 1e-9,
        "Torsional capacity does not match analytic result.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end TorsionalCapacityTest;
  
    model LegacyTorsionalEdgeCasesTest
      "LEGACY diagnostic function: negligible-load COP sentinel and normal-load clipping"
      Real capacity[4],radius[4],cop[4,2];
      output Real observedCapacity[4]=capacity;
      output Real observedRadius[4]=radius;
      output Real observedCOP[4,2]=cop;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      (capacity[1],radius[1],cop[1,:])=ModelicaHumanBodyPArts.Contact.torsionalCapacity(
        1,[2,3,0],{0},0.2,1e-9);
      (capacity[2],radius[2],cop[2,:])=ModelicaHumanBodyPArts.Contact.torsionalCapacity(
        1,[2,3,0],{1e-12},0.2,1e-9);
      (capacity[3],radius[3],cop[3,:])=ModelicaHumanBodyPArts.Contact.torsionalCapacity(
        2,[100,100,0;2,3,0],{-100,100},0.2,1e-9);
      (capacity[4],radius[4],cop[4,:])=ModelicaHumanBodyPArts.Contact.torsionalCapacity(
        1,[2,3,0],{1e-9},0.2,1e-9);
      assert(max(abs(capacity))<1e-12 and max(abs(radius))<1e-12,
        "Zero-radius legacy capacities must vanish.");
      assert(max(abs(cop[1,:]))<1e-15 and max(abs(cop[2,:]))<1e-15 and max(abs(cop[4,:]))<1e-15,
        "Undefined legacy COP must be the zero storage sentinel.");
      assert(max(abs(cop[3,:]-{2,3}))<1e-12,"Negative-load clipping must not bias COP.");
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(capacity))<1e-12 and max(abs(radius))<1e-12,
        "Zero-radius legacy capacities must vanish.");
        assert(max(abs(cop[1,:]))<1e-15 and max(abs(cop[2,:]))<1e-15 and max(abs(cop[4,:]))<1e-15,
        "Undefined legacy COP must be the zero storage sentinel.");
        assert(max(abs(cop[3,:]-{2,3}))<1e-12,"Negative-load clipping must not bias COP.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end LegacyTorsionalEdgeCasesTest;
  
    model ResidualSpinBudgetTest
      Modelica.Units.SI.Torque cap;
      Modelica.Units.SI.Torque capZone[4];
      Modelica.Units.SI.Torque freeCap;
      Modelica.Units.SI.Torque freeZone[4];
      output Real observedSaturatedCapacity=cap;
      output Real observedFreeCapacity=freeCap;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      (cap,capZone)=ModelicaHumanBodyPArts.Contact.residualSpinCapacity(
        4,fill(100,4),[60,0;60,0;60,0;60,0],0.6,fill(0.01,4),1);
      (freeCap,freeZone)=ModelicaHumanBodyPArts.Contact.residualSpinCapacity(
        4,fill(100,4),zeros(4,2),0.6,fill(0.01,4),1);
      assert(abs(cap)<1e-12, "Saturated local shear cannot retain independent spin capacity.");
      assert(abs(freeCap-1.6)<1e-12, "Uniform-disk no-shear capacity incorrect.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(cap)<1e-12, "Saturated local shear cannot retain independent spin capacity.");
        assert(abs(freeCap-1.6)<1e-12, "Uniform-disk no-shear capacity incorrect.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-8));
    end ResidualSpinBudgetTest;
  
    model PlantarContactSpinTest
      "Driven synthetic rigid-foot spin on elevated plane; analytical wrench/spin oracle"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
    
      parameter Real omega=0.1;
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor(r={0,0,0.379},animation=false);
      Modelica.Mechanics.MultiBody.Joints.Revolute spin(n={0,0,1},useAxisFlange=true);
      Modelica.Mechanics.Rotational.Sources.Position drive(exact=true,useSupport=false);
      Modelica.Blocks.Sources.RealExpression angle(y=omega*time);
      ModelicaHumanBodyPArts.Segments.Foot foot(props=footProps,footWidth=0.095,
        ankleFromHeel=0.07,ankleHeight=0.08,animation=false);
      ModelicaHumanBodyPArts.Contact.PlantarContact contact(groundHeight=0.3,
        kNormal=100000,cNormal=0,mu=0.6,vSlip=0.01,
        torsionalFrictionFactor=0.8,patchRadius=fill(0.005,6),omegaTorsionSlip=0.05);
      output Real observedGRF[3]=contact.groundReactionForce;
      output Real observedCOP[2]=contact.cop;
      output Real observedCapacity=contact.torsionalCapacity;
      output Real observedFreeYaw=contact.yawFromFreeMoment;
      output Real observedShearYaw=contact.yawFromShear;
      output Real observedTotalYaw=contact.yawTotal;
      output Real observedSpin=spin.w;
      output Real observedFrictionUtilization=contact.torsionalUtilization;
      parameter Modelica.Units.SI.Time verificationTime=0.090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(anchor.frame_b,spin.frame_a);
      connect(angle.y,drive.phi_ref);
      connect(drive.flange,spin.axis);
      connect(spin.frame_b,foot.frame_ankle);
      connect(foot.frame_ankle,contact.frame_torsion);
      for i in 1:6 loop
        connect(foot.frame_plantar[i],contact.plantarFrames[i]);
      end for;
      assert(abs(observedGRF[3]-600)<1e-5 and contact.copValid,"Six-zone normal force/valid COP failed.");
      assert(observedCapacity>0 and observedFreeYaw<0,
        "Active residual spin must be nonzero and dissipative.");
      assert(abs(observedTotalYaw-observedShearYaw-observedFreeYaw)<1e-8,"Yaw channels do not close.");
      assert(observedFrictionUtilization<=1+1e-10,"Spin utilization exceeds conservative capacity.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(observedGRF[3]-600)<1e-5 and contact.copValid,"Six-zone normal force/valid COP failed.");
        assert(observedCapacity>0 and observedFreeYaw<0,
        "Active residual spin must be nonzero and dissipative.");
        assert(abs(observedTotalYaw-observedShearYaw-observedFreeYaw)<1e-8,"Yaw channels do not close.");
        assert(observedFrictionUtilization<=1+1e-10,"Spin utilization exceeds conservative capacity.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.1,Tolerance=1e-9));
    end PlantarContactSpinTest;
  
    model JointLimitMonitorTest
      "Five reached assertion stages: outside/lower/interior/upper/outside, plus ties"
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(
        n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter Real bankQ[7,3]={{0,0,0},{-1,0,0},{0,1,0},{0,0,1.1},
        {-0.5,0.9,0},{0.9,-0.9,0},{0,-1.2,0}};
      parameter Integer nearest[7]={1,1,2,3,2,1,2};
      parameter Integer ties[7]={3,1,1,1,1,2,1};
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor bank[7](each n=3,each mobility=rom);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor sweep(n=3,mobility=rom);
      output Integer checksPassed(start=0,fixed=true)
        "Completed timed assertion stages, not assertion count";
      output Real observedSweepUtilization=sweep.utilization[1];
      output Real observedSweepMargin=sweep.distanceToLimit[1];
      output Real observedTieCount=bank[6].nearestMarginCount;
      output Real observedTieIndex=bank[6].limitingDOF;
    equation
      sweep.q={-1.25+2.5*time,0,0};
      for i in 1:7 loop
        bank[i].q=bankQ[i,:];
        assert(bank[i].limitingDOF==nearest[i],"Nearest DOF identity/tie-breaking failure.");
        assert(bank[i].nearestMarginCount==ties[i],"Nearest-margin tie reporting failure.");
      end for;
      assert(not bank[1].atLimit[1] and not bank[1].violated[1],"Interior misclassified.");
      assert(bank[2].atLimit[1] and not bank[2].violated[1],"Lower boundary misclassified.");
      assert(bank[3].atLimit[2] and not bank[3].violated[2],"Upper boundary misclassified.");
      assert(bank[4].violated[3] and bank[7].violated[2],"Outside cases missed.");
      assert(bank[6].nearestMarginTie[1] and bank[6].nearestMarginTie[2]
        and not bank[6].nearestMarginTie[3],"Tie mask is incorrect.");
    algorithm
      when {time>=0.05,time>=0.10,time>=0.50,time>=0.90,time>=0.99} then
        if time<0.075 then
          assert(sweep.violated[1] and sweep.marginLower[1]<0,"Lower outside sweep case missed.");
        elseif time<0.30 then
          assert(abs(sweep.marginLower[1])<1e-8 and sweep.atLimit[1]
            and not sweep.violated[1],"Lower boundary event missed.");
        elseif time<0.70 then
          assert(abs(sweep.utilization[1])<1e-8 and not sweep.atLimit[1],"Interior event missed.");
        elseif time<0.95 then
          assert(abs(sweep.marginUpper[1])<1e-8 and sweep.atLimit[1]
            and not sweep.violated[1],"Upper boundary event missed.");
        else
          assert(sweep.violated[1] and sweep.marginUpper[1]<0,"Upper outside event missed.");
        end if;
        checksPassed:=pre(checksPassed)+1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1.0,Tolerance=1e-9,Interval=0.001));
    end JointLimitMonitorTest;
  
    model ScalingSmokeTest
      "Static assertions for v0.2 scaling resolution"
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile p(
        height=1.75,
        mass=75,
        sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26,
        footWidth=0.095,
        ankleFromHeel=0.07,
        ankleHeight=0.08,
        shankLength=0.43,
        thighLength=0.44,
        pelvisLength=0.18,
        hipCenterDistance=0.20);
    
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties foot =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(p, ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shank =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(p, ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thigh =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(p, ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties pelvis =
        ModelicaHumanBodyPArts.Scaling.resolveSegment(p, ModelicaHumanBodyPArts.Types.SegmentKey.Pelvis);
    
      output Real observedFootMass=foot.mass;
      output Real observedShankMass=shank.mass;
      output Real observedThighMass=thigh.mass;
      output Real observedPelvisMass=pelvis.mass;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    initial algorithm
      assert(abs(foot.mass/p.mass - 0.0137) < 1e-12, "Male foot mass fraction mismatch.");
      assert(abs(shank.mass/p.mass - 0.0433) < 1e-12, "Male shank mass fraction mismatch.");
      assert(abs(thigh.mass/p.mass - 0.1416) < 1e-12, "Male thigh mass fraction mismatch.");
      assert(abs(pelvis.mass/p.mass - 0.1117) < 1e-12, "Male pelvis mass fraction mismatch.");
    
      assert(foot.ISagittal > 0 and foot.ITransverse > 0 and foot.ILongitudinal > 0,
        "Foot inertias must be positive.");
      assert(shank.ISagittal > 0 and thigh.ISagittal > 0 and pelvis.ISagittal > 0,
        "All resolved segment inertias must be positive.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(foot.mass/p.mass - 0.0137) < 1e-12, "Male foot mass fraction mismatch.");
        assert(abs(shank.mass/p.mass - 0.0433) < 1e-12, "Male shank mass fraction mismatch.");
        assert(abs(thigh.mass/p.mass - 0.1416) < 1e-12, "Male thigh mass fraction mismatch.");
        assert(abs(pelvis.mass/p.mass - 0.1117) < 1e-12, "Male pelvis mass fraction mismatch.");
        assert(foot.ISagittal > 0 and foot.ITransverse > 0 and foot.ILongitudinal > 0,
        "Foot inertias must be positive.");
        assert(shank.ISagittal > 0 and thigh.ISagittal > 0 and pelvis.ISagittal > 0,
        "All resolved segment inertias must be positive.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end ScalingSmokeTest;
  
    model FootCOMOffsetTest
      "COM coordinate bookkeeping only; 30 mm override is a synthetic test, not anatomical data"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=
        ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
    
      ModelicaHumanBodyPArts.Segments.Foot baseline(props=footProps,footWidth=0.095,
        ankleFromHeel=0.07,ankleHeight=0.08,animation=false);
      ModelicaHumanBodyPArts.Segments.Foot offset(props=footProps,footWidth=0.095,
        ankleFromHeel=0.07,ankleHeight=0.08,comAboveSole=0.03,
        comOffsetSourceId="SYNTHETIC_VERIFICATION_ONLY",animation=false);
      output Real observedBaseline[3]=baseline.comPositionLocal;
      output Real observedOffset[3]=offset.comPositionLocal;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(world.frame_b,baseline.frame_ankle);
      connect(world.frame_b,offset.frame_ankle);
      assert(abs(observedBaseline[3]+0.08)<1e-12,"Legacy sole-plane default changed silently.");
      assert(abs(observedOffset[3]+0.05)<1e-12,"Explicit COM offset mapping failed.");
      assert(abs(observedOffset[1]-(0.4415*0.26-0.07))<1e-12,"COM longitudinal origin changed.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(observedBaseline[3]+0.08)<1e-12,"Legacy sole-plane default changed silently.");
        assert(abs(observedOffset[3]+0.05)<1e-12,"Explicit COM offset mapping failed.");
        assert(abs(observedOffset[1]-(0.4415*0.26-0.07))<1e-12,"COM longitudinal origin changed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end FootCOMOffsetTest;
  
    model AffineMassPropertiesTest
      Modelica.Units.SI.Position c[3];
      Modelica.Units.SI.Inertia I[3,3];
      parameter Modelica.Units.SI.Mass m=2;
      parameter Modelica.Units.SI.Length a=0.2,b=0.3,d=0.4;
      parameter Modelica.Units.SI.Inertia I0[3,3]=diagonal(
        {m*(b*b+d*d)/12,m*(a*a+d*d)/12,m*(a*a+b*b)/12});
      parameter Modelica.Units.SI.Inertia target[3,3]=diagonal(
        {3*((0.3*0.5)^2+(0.4*1.5)^2)/12,
         3*((0.2*2)^2+(0.4*1.5)^2)/12,
         3*((0.2*2)^2+(0.3*0.5)^2)/12});
      output Real observedCOM[3]=c;
      output Real observedInertia[3,3]=I;
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      (c,I)=ModelicaHumanBodyPArts.Utilities.affineMassProperties(m,{0,0,0},I0,
        diagonal({2,0.5,1.5}),{0.1,-0.2,0.3},3);
      assert(max(abs(I-target))<1e-12 and max(abs(c-{0.1,-0.2,0.3}))<1e-12,
        "Affine box mass-property test failed.");
      assert(not ModelicaHumanBodyPArts.Utilities.physicalInertia(diagonal({1,1,3})),
        "Positive but nonphysical inertia was accepted.");
    
    algorithm
      when time>=verificationTime then
        assert(max(abs(I-target))<1e-12 and max(abs(c-{0.1,-0.2,0.3}))<1e-12,
        "Affine box mass-property test failed.");
        assert(not ModelicaHumanBodyPArts.Utilities.physicalInertia(diagonal({1,1,3})),
        "Positive but nonphysical inertia was accepted.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-8));
    end AffineMassPropertiesTest;
  
    model PhysicalPendulumTest
      "Uniform cylinder pendulum: synthetic mechanical verification, not human validation"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(n={0,0,-1},g=9.81);
      parameter SI.Mass m=3;
      parameter SI.Length L=0.43;
      parameter SI.Length radius=0.03;
      parameter SI.Angle q0=0.3;
      parameter SI.Inertia Ic=m*(L^2+3*radius^2)/12;
      parameter SI.Inertia J=Ic+m*(L/2)^2;
      parameter SI.Energy E0=m*9.81*(L/2)*(1-cos(q0));
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties props(
        mass=m,length=L,comFraction=0.5,comDistance=L/2,
        ISagittal=Ic,ITransverse=Ic,ILongitudinal=m*radius^2/2,
        sourceId="Synthetic uniform cylinder; analytic reference only");
      Modelica.Mechanics.MultiBody.Joints.Revolute joint(
        n={0,1,0},phi(start=q0,fixed=true),w(start=0,fixed=true));
      ModelicaHumanBodyPArts.Segments.Shank rod(props=props,animation=false);
      output SI.Angle q=joint.phi;
      output SI.Energy energy=0.5*J*joint.w^2+m*9.81*(L/2)*(1-cos(joint.phi));
      output Real relativeEnergyError=(energy-E0)/E0;
      parameter Modelica.Units.SI.Time verificationTime=4.8695229516542584;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    equation
      connect(world.frame_b,joint.frame_a);
      connect(joint.frame_b,rod.frame_proximal);
      assert(abs(relativeEnergyError)<1e-5,"Pendulum energy check failed.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(relativeEnergyError)<1e-5,"Pendulum energy check failed.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=5.41058105739362,Tolerance=1e-8));
    end PhysicalPendulumTest;
  
    model ROMSourceSideTest
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile L(n=1)=
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.kneeMean(true);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile R(n=1)=
        ModelicaHumanBodyPArts.Data.RoaasAndersson1982.kneeMean(false);
      output Real observedLeftMin=Modelica.Units.Conversions.to_deg(L.qMin[1]);
      output Real observedRightMin=Modelica.Units.Conversions.to_deg(R.qMin[1]);
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    initial equation
      assert(abs(Modelica.Units.Conversions.to_deg(L.qMin[1])+1.7)<1e-10,
        "Left knee source mean incorrect.");
      assert(abs(Modelica.Units.Conversions.to_deg(R.qMin[1])+1.6)<1e-10,
        "Right knee source mean incorrect.");
      assert(L.romNature==ModelicaHumanBodyPArts.Types.ROMNature.Passive and L.hasUncertainty,
        "Passive population-SD metadata missing.");
    
    algorithm
      when time>=verificationTime then
        assert(abs(Modelica.Units.Conversions.to_deg(L.qMin[1])+1.7)<1e-10,
        "Left knee source mean incorrect.");
        assert(abs(Modelica.Units.Conversions.to_deg(R.qMin[1])+1.6)<1e-10,
        "Right knee source mean incorrect.");
        assert(L.romNature==ModelicaHumanBodyPArts.Types.ROMNature.Passive and L.hasUncertainty,
        "Passive population-SD metadata missing.");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-8));
    end ROMSourceSideTest;
  
    model PublishedSourceTablesTest
      "Table-transcription regression; not biological validation"
      parameter ModelicaHumanBodyPArts.Records.BSIPCoefficients maleShank =
        ModelicaHumanBodyPArts.Data.DeLeva1996.male(ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.BSIPCoefficients femaleShank =
        ModelicaHumanBodyPArts.Data.DeLeva1996.female(ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.PublishedBSIPRow riderShank =
        ModelicaHumanBodyPArts.Data.Bova2020LowerLimb.deLevaRiderRow(ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.PublishedBSIPRow riderFoot =
        ModelicaHumanBodyPArts.Data.Bova2020LowerLimb.dumasRiderRow(ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      output Real observedMaleShankCOM=maleShank.comFraction;
      output Real observedFemaleShankCOM=femaleShank.comFraction;
      output Real observedBovaShankBeta=riderShank.beta[3];
      output Real observedFootRef=riderFoot.lengthPerStature;
      output Real observedCrossRadius=riderFoot.crossEta[3];
      parameter Modelica.Units.SI.Time verificationTime=0.0090000000000000011;
      output Integer checksPassed(start=0,fixed=true) "Completed assertion stage";
    initial equation
      assert(abs(maleShank.comFraction-0.4395)<1e-12,"HAS male shank COM transcription");
      assert(abs(femaleShank.comFraction-0.4352)<1e-12,"HAS female shank COM transcription");
      assert(abs(riderShank.beta[3]+0.4459)<1e-12,"Keep Bova normalization distinct");
      assert(abs(riderFoot.lengthPerStature-0.1034)<1e-12,"Do not use full heel-to-toe scaling");
      assert(abs(riderFoot.crossEta[3]-0.13)<1e-12,"Table A6 xz cross radius retained");
      assert(not riderFoot.tensorConversionApproved,"Unverified tensor adapter cannot be enabled");
    
    algorithm
      when time>=verificationTime then
        assert(abs(maleShank.comFraction-0.4395)<1e-12,"HAS male shank COM transcription");
        assert(abs(femaleShank.comFraction-0.4352)<1e-12,"HAS female shank COM transcription");
        assert(abs(riderShank.beta[3]+0.4459)<1e-12,"Keep Bova normalization distinct");
        assert(abs(riderFoot.lengthPerStature-0.1034)<1e-12,"Do not use full heel-to-toe scaling");
        assert(abs(riderFoot.crossEta[3]-0.13)<1e-12,"Table A6 xz cross radius retained");
        assert(not riderFoot.tensorConversionApproved,"Unverified tensor adapter cannot be enabled");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end PublishedSourceTablesTest;
  
    model S45ReplayTest
      "Imported scalar replay fixture, with an explicit timed completion check"
      Modelica.Units.SI.Angle qa,qk;
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.005;
    equation
      (qa,qk)=ModelicaHumanBodyPArts.CanonicalReplay.s45Kinematics(0.4);
    algorithm
      when time>=verificationTime then
        assert(abs(qa*180/Modelica.Constants.pi-12)<1e-9,"S45 ankle mismatch");
        assert(abs(qk*180/Modelica.Constants.pi-3.4542794188062427)<1e-9,"S45 knee mismatch");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9,Interval=0.0001));
    end S45ReplayTest;
  
    model S46ReplayTest
      "Imported scalar replay fixture, with an explicit timed completion check"
      Modelica.Units.SI.Force F;
      Modelica.Units.SI.Angle q;
      Modelica.Units.SI.Position cu,cs;
      Real hu,hs;
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.005;
    equation
      (F,q,cu,cs,hu,hs)=ModelicaHumanBodyPArts.CanonicalReplay.s46Diagnostics(x=0.4,a=0,beta=0.09375);
    algorithm
      when time>=verificationTime then
        assert(abs(F-68.9765625)<1e-9,"S46 force mismatch");
        assert(abs(cu-0.15)<1e-12 and abs(hu)<1e-12,"S46 heel threshold mismatch");
        assert(abs(q*180/Modelica.Constants.pi-14.477512185929925)<1e-9,"S46 ankle mismatch");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9,Interval=0.0001));
    end S46ReplayTest;
  

    model AuditedPlantarKnownLoadTest
      "Known-answer six-zone regional-load and static energy audit"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter Real k(unit="N/m")=100000;
      parameter Modelica.Units.SI.Length delta=0.0001635;
      Modelica.Mechanics.MultiBody.Parts.Fixed base(animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z[6](each r={0,0,-delta},each animation=false);
      ModelicaHumanBodyPArts.Contact.AuditedPlantarContact contact(kNormal=k,cNormal=0,mu=0,vSlip=0.01);
      output Modelica.Units.SI.Force totalNormal=sum(contact.zoneNormalForce);
      output Integer checksPassed(start=0,fixed=true);
    equation
      for i in 1:6 loop connect(base.frame_b,z[i].frame_a); connect(z[i].frame_b,contact.plantarFrames[i]); end for;
      connect(base.frame_b,contact.frame_torsion);
    algorithm
      when time>=0.009 then
        assert(abs(totalNormal-98.1)<1e-6,"Known total normal load failed");
        assert(abs(contact.heelLoad-32.7)<1e-6 and abs(contact.midfootLoad-32.7)<1e-6 and abs(contact.forefootLoad-32.7)<1e-6,"Regional load split failed");
        assert(contact.broadSupport and abs(contact.heelShare-1/3)<1e-10,"Regional support observer failed");
        assert(abs(contact.lossPower)<1e-10 and abs(contact.powerToBody)<1e-10 and abs(contact.identityResidual)<1e-8,"Static contact energy audit failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9,Interval=0.0001));
    end AuditedPlantarKnownLoadTest;

    model AuditedPlantarHeelUnloadTest
      "Observer distinguishes supported foot with unloaded heel from broad support"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter Real k(unit="N/m")=100000;
      Modelica.Mechanics.MultiBody.Parts.Fixed base(animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z1(r={0,0,0.001},animation=false),z2(r={0,0,0.001},animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation z3(r={0,0,-0.0002},animation=false),z4(r={0,0,-0.0002},animation=false),z5(r={0,0,-0.0002},animation=false),z6(r={0,0,-0.0002},animation=false);
      ModelicaHumanBodyPArts.Contact.AuditedPlantarContact contact(kNormal=k,cNormal=0,mu=0,vSlip=0.01);
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(base.frame_b,z1.frame_a);connect(z1.frame_b,contact.plantarFrames[1]);
      connect(base.frame_b,z2.frame_a);connect(z2.frame_b,contact.plantarFrames[2]);
      connect(base.frame_b,z3.frame_a);connect(z3.frame_b,contact.plantarFrames[3]);
      connect(base.frame_b,z4.frame_a);connect(z4.frame_b,contact.plantarFrames[4]);
      connect(base.frame_b,z5.frame_a);connect(z5.frame_b,contact.plantarFrames[5]);
      connect(base.frame_b,z6.frame_a);connect(z6.frame_b,contact.plantarFrames[6]);
      connect(base.frame_b,contact.frame_torsion);
    algorithm
      when time>=0.009 then
        assert(contact.supportValid and contact.heelLoad<1e-9,"Heel unload fixture did not unload heel");
        assert(not contact.broadSupport,"Broad-support observer failed to reject heel-unloaded support");
        assert(abs(contact.midfootLoad-40)<1e-6 and abs(contact.forefootLoad-40)<1e-6,"Supported regional loads incorrect");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9,Interval=0.0001));
    end AuditedPlantarHeelUnloadTest;


    model LoadedSupportVariableImpedanceEnergyTest
      "Aggregate variable-impedance energy ledger on the gravity-loaded articulated body"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(n={0,0,-1},g=9.81,gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.18,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_ENERGY_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,rCM={0,0,-0.05},I_CM={{0.1,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_ENERGY_PELVIS");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.5,rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1}},R_principal=identity(3),segmentFrameId="SYNTHETIC_ENERGY_TRUNK");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-0.5,-0.7,-0.7},qMax={2.2,0.7,0.7},sourceId="SYNTHETIC_ENERGY_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-0.15},qMax={2.8},sourceId="SYNTHETIC_ENERGY_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-0.8,-0.6},qMax={0.8,0.6},sourceId="SYNTHETIC_ENERGY_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin=fill(-0.5,3),qMax=fill(0.5,3),sourceId="SYNTHETIC_ENERGY_ROM");
      parameter SI.Angle initialQ[15]={0,0,0,0,0,-0.115275665089173,0.25,0,0,0.5,0.25,0.115275665089173,0,0,0};
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,0.08},animation=false);
      ModelicaHumanBodyPArts.Transmission.SmoothImpedanceSchedule schedule(preparationEnd=0.10,releaseEnd=0.40,initialScale=1,preparationScale=1,releaseScale=0.6);
      ModelicaHumanBodyPArts.SupportInitiation.LoadedSupportBody body(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.1,shoulderWidth=0.4,footCOMAboveSole=0.035,footCOMOffsetSourceId="SYNTHETIC_ENERGY_OFFSET",hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,leftHipStart=initialQ[1:3],leftKneeStart=initialQ[4],leftAnkleStart=initialQ[5:6],rightHipStart=initialQ[7:9],rightKneeStart=initialQ[10],rightAnkleStart=initialQ[11:12],lumbarStart=initialQ[13:15],fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed=fill(true,3),lumbarWFixed=fill(true,3),useVariableImpedance=true,animation=false);
      output SI.Energy dampingLoss(start=0,fixed=true);
      output SI.Energy modulationWorkToMechanical(start=0,fixed=true);
      output SI.Energy energyResidual=body.mechanicalEnergy-energy0+dampingLoss+modulationWorkToMechanical;
      output Integer checksPassed(start=0,fixed=true);
    protected
      parameter SI.Energy energy0(fixed=false);
    initial equation
      energy0=body.mechanicalEnergy;
    equation
      connect(support.frame_b,body.leftFootReference);
      body.ankleActuation=0; body.hipYawActuation=0;
      body.leftHipControl=cat(1,fill(schedule.scale,3),fill(schedule.scale,3),fill(schedule.scaleRate,3));
      body.rightHipControl=body.leftHipControl;
      body.lumbarControl=body.leftHipControl;
      der(dampingLoss)=body.dissipationPower;
      der(modulationWorkToMechanical)=body.totalStiffnessModulationPower;
    algorithm
      when time>=0.49 then
        assert(abs(energyResidual)<1e-4,"Aggregate variable-impedance energy ledger failed");
        assert(abs(body.actualStiffness[1]-0.6*body.stiffness[1])<1e-8 and abs(body.actualDamping[1]-0.6*body.damping[1])<1e-8,"Actual coefficient reporting failed");
        assert(body.dissipationPower>=-1e-9,"Aggregate dissipation became negative");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.5,Tolerance=1e-8,Interval=0.001));
    end LoadedSupportVariableImpedanceEnergyTest;

  end Tests;

  package Utilities
    extends Modelica.Icons.Package;
  
    function physicalInertia
      "Check symmetric positive I and nonnegative second mass moment (triangle inequalities)"
      input Real I[3,3];
      input Real relTol=1e-10;
      output Boolean valid;
    protected
      Real S[3,3]; Real J[3,3]; Real scale; Real symError; Real tr;
    algorithm
      scale := max(1e-30,max(abs(I)));
      J := I/scale;
      tr := J[1,1]+J[2,2]+J[3,3];
      symError := max(abs(J-transpose(J)));
      S := 0.5*tr*identity(3)-J;
      valid := symError<=relTol and J[1,1]>0 and
        J[1,1]*J[2,2]-J[1,2]^2>0 and Modelica.Math.Matrices.det(J)>0 and
        min({S[1,1],S[2,2],S[3,3]})>=-relTol and
        S[1,1]*S[2,2]-S[1,2]^2>=-relTol and
        S[1,1]*S[3,3]-S[1,3]^2>=-relTol and
        S[2,2]*S[3,3]-S[2,3]^2>=-relTol and
        Modelica.Math.Matrices.det(S)>=-relTol;
    end physicalInertia;
  
    function affineMassProperties
      "Mass-renormalized affine pushforward; exact for the assumed transformed density"
      import SI = Modelica.Units.SI;
      input SI.Mass massReference;
      input SI.Position rCMReference[3];
      input SI.Inertia inertiaReference[3,3];
      input Real A[3,3] "Invertible stretch/rotation map applied to all source points";
      input SI.Position b[3] "Translation of mapped points";
      input SI.Mass massTarget;
      output SI.Position rCM[3];
      output SI.Inertia I_CM[3,3];
    protected
      SI.Inertia S[3,3]; SI.Inertia Snew[3,3];
    algorithm
      assert(massReference>0 and massTarget>0, "Masses must be positive.");
      assert(abs(Modelica.Math.Matrices.det(A))>1e-12, "Affine map must be invertible.");
      assert(physicalInertia(inertiaReference), "Nonphysical source inertia.");
      S := 0.5*(inertiaReference[1,1]+inertiaReference[2,2]+inertiaReference[3,3])
        *identity(3)-inertiaReference;
      Snew := (massTarget/massReference)*A*S*transpose(A);
      rCM := A*rCMReference+b;
      I_CM := (Snew[1,1]+Snew[2,2]+Snew[3,3])*identity(3)-Snew;
      assert(physicalInertia(I_CM), "Nonphysical mapped inertia.");
      annotation(Inline=false, Documentation(info="<html><p>New project derivation from the second mass
      moment S=integral (r-c)(r-c)' dm. Handles unequal axial/cross-sectional scaling.
      It is NOT an empirically validated human allometry or population regression.</p></html>"));
    end affineMassProperties;
  
    function shiftInertia
      "Rotate COM inertia into a reporting frame, then shift to another origin"
      input Modelica.Units.SI.Inertia I_CM[3,3];
      input Real R[3,3] "Maps local vectors to reporting-frame vectors";
      input Modelica.Units.SI.Mass mass;
      input Modelica.Units.SI.Position d[3] "New origin to COM, in reporting frame";
      output Modelica.Units.SI.Inertia I_O[3,3];
    algorithm
      assert(mass>0, "Mass must be positive.");
      assert(max(abs(transpose(R)*R-identity(3)))<1e-9 and
        abs(Modelica.Math.Matrices.det(R)-1)<1e-9, "R must be a proper rotation.");
      I_O := R*I_CM*transpose(R)+mass*((d*d)*identity(3)-outerProduct(d,d));
    end shiftInertia;
  
  end Utilities;

  package BuildFixtures
    "Fully specified assembly translation/build roots; no biomechanical validity claim"
    extends Modelica.Icons.ExamplesPackage;
  
    model LowerBodyAssemblyBuild
      "Build fixture only: fixed pelvis, specified joint initialization, synthetic dimensions"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
    
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,1.1299999999999999},animation=false);
      ModelicaHumanBodyPArts.Assemblies.LowerBodyAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,animation=false);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end LowerBodyAssemblyBuild;
  
    model LowerBodyGroundedBuild
      "Build fixture only: fixed pelvis, specified joint initialization, synthetic dimensions"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
    
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,1.1299999999999999},animation=false);
      ModelicaHumanBodyPArts.Assemblies.LowerBodyGroundedAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,groundHeight=0,
        torsionalFrictionFactor=0,patchRadius=fill(0.005,6),kNormal=10000,cNormal=100);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end LowerBodyGroundedBuild;
  
    model LowerBodyGroundedElevatedSpinBuild
      "Build fixture only: fixed pelvis, specified joint initialization, synthetic dimensions"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75, mass=75, sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26, footWidth=0.095, ankleFromHeel=0.07, ankleHeight=0.08,
        shankLength=0.43, thighLength=0.44, pelvisLength=0.18, hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_VERIFICATION_FIXTURE");
    
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,1.48},animation=false);
      ModelicaHumanBodyPArts.Assemblies.LowerBodyGroundedAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,groundHeight=0.35,
        torsionalFrictionFactor=0.8,patchRadius=fill(0.005,6),kNormal=10000,cNormal=100);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end LowerBodyGroundedElevatedSpinBuild;
  
  end BuildFixtures;

  package Benchmarks "Synthetic assembled-mechanics verification; not measured human movement"
    extends Modelica.Icons.ExamplesPackage;
  
    partial model PartialFixture "Declared synthetic dimensions and fixed-pelvis boundary"
      parameter Real scaleFactor(min=0.1)=1;
      parameter Modelica.Units.SI.Mass bodyMass=75;
      parameter Modelica.Units.SI.Position rootHeight=1.10*scaleFactor;
      inner Modelica.Mechanics.MultiBody.World world(g=9.81,n={0,0,-1},enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75*scaleFactor,mass=bodyMass,sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=.26*scaleFactor,footWidth=.095*scaleFactor,
        ankleFromHeel=.07*scaleFactor,ankleHeight=.08*scaleFactor,
        shankLength=.43*scaleFactor,thighLength=.44*scaleFactor,
        pelvisLength=.18*scaleFactor,hipCenterDistance=.20*scaleFactor,
        geometrySourceId="SYNTHETIC_ASSEMBLED_BENCHMARK_NOT_HUMAN_DATA");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,
        qMin={-4,-2,-4},qMax={4,2,4},sourceId="SYNTHETIC_DIAGNOSTIC_ONLY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,
        qMin={-4},qMax={4},sourceId="SYNTHETIC_DIAGNOSTIC_ONLY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,
        qMin={-4,-2},qMax={4,2},sourceId="SYNTHETIC_DIAGNOSTIC_ONLY");
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,rootHeight},animation=false);
    end PartialFixture;
  
    model FreeSwing "Unactuated bilateral articulated chain; a planar invariant benchmark"
      extends PartialFixture;
      ModelicaHumanBodyPArts.Assemblies.LowerBodyAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
        leftHipStart={.4,0,0},rightHipStart={.4,0,0},
        leftKneeStart=.8,rightKneeStart=.8,leftAnkleStart={.4,0},rightAnkleStart={.4,0},
        animation=false);
      output Modelica.Units.SI.Angle qL[6],qR[6];
      output Modelica.Units.SI.AngularVelocity wL[6],wR[6];
      output Modelica.Units.SI.AngularAcceleration aL[6],aR[6];
      output Modelica.Units.SI.Force supportForce[3];
      output Modelica.Units.SI.Mass representedMass;
      output Integer completed(start=0,fixed=true);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      qL=body.leftQ; qR=body.rightQ;
      wL=der(qL);wR=der(qR);aL=der(wL);aR=der(wR);
      supportForce=body.frame_pelvisProximal.f;
      representedMass=body.representedMass;
    algorithm
      when time>=1.49 then
        assert(max(abs(qL-qR))<1e-7,"Bilateral symmetry lost in free-swing fixture");
        completed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.0005));
    end FreeSwing;
  
    model GroundedRelease "Fixed-pelvis articulated release into compliant ground; not human stance"
      extends PartialFixture;
      parameter Real stiffness(unit="N/m")=100000;
      parameter Real damping(unit="N.s/m")=500;
      parameter Real friction=0.7;
      parameter Modelica.Units.SI.Velocity slipSpeed=0.01;
      ModelicaHumanBodyPArts.Assemblies.LowerBodyGroundedAssembly body(
        profile=profile,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
        leftHipStart={.4,0,0},rightHipStart={.4,0,0},leftKneeStart=.8,rightKneeStart=.8,
        leftAnkleStart={.4,0},rightAnkleStart={.4,0},groundHeight=0,
        kNormal=stiffness,cNormal=damping,mu=friction,vSlip=slipSpeed,
        torsionalFrictionFactor=0,patchRadius=fill(.005,6));
      output Modelica.Units.SI.Angle qL[6],qR[6];
      output Modelica.Units.SI.AngularVelocity wL[6],wR[6];
      output Modelica.Units.SI.AngularAcceleration aL[6],aR[6];
      output Modelica.Units.SI.Force supportForce[3],groundForce[3];
      output Modelica.Units.SI.Mass representedMass;
      output Modelica.Units.SI.Power contactPower;
      output Modelica.Units.SI.Energy contactWork(start=0,fixed=true);
      output Modelica.Units.SI.Length maxPenetration;
      output Integer completed(start=0,fixed=true);
    equation
      connect(support.frame_b,body.frame_pelvisProximal);
      qL=body.leftQ;qR=body.rightQ;wL=der(qL);wR=der(qR);aL=der(wL);aR=der(wR);
      representedMass=body.representedMass;
      supportForce=body.frame_pelvisProximal.f;groundForce=body.leftGRF+body.rightGRF;
      contactPower=sum(body.leftZoneForce[i,:]*der(body.leftZonePosition[i,:])
        +body.rightZoneForce[i,:]*der(body.rightZonePosition[i,:]) for i in 1:6);
      der(contactWork)=contactPower;
      maxPenetration=max(0,max(-body.leftZonePosition[:,3]));
    algorithm
      when time>=.499 then
        assert(max(abs(qL-qR))<1e-6,"Bilateral symmetry lost in grounded fixture");
        completed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=.5,Tolerance=1e-8,Interval=.0001));
    end GroundedRelease;
  
  end Benchmarks;

  package CanonicalReplay
    "Historical scalar replays; not integrated human-body dynamics"
    extends Modelica.Icons.Package;
    annotation(Documentation(info="<html><p>Imported from the supplied v0.8 branch."
      + " Prescribed S45/S46 diagnostics are separate from the articulated body."
      + " Signed heel requirements outside [0,1] identify infeasibility."
      + " They are not admissible physical contact loads."
      + " See the Test Report for execution status and historical evidence.</p></html>"));
  
    function quinticKinematics
      "Prescribed quintic source trajectory, stationary before zero and after T"
      input Modelica.Units.SI.Time t;
      input Modelica.Units.SI.Length D;
      input Modelica.Units.SI.Time T;
      output Modelica.Units.SI.Position x;
      output Modelica.Units.SI.Velocity v;
      output Modelica.Units.SI.Acceleration a;
    protected
      Real u;
    algorithm
      assert(T > 0 and D >= 0, "Require T > 0 and D >= 0");
      u := min(1, max(0, t/T));
      x := D*(10*u^3 - 15*u^4 + 6*u^5);
      v := D/T*(30*u^2 - 60*u^3 + 30*u^4);
      a := D/T^2*(60*u - 180*u^2 + 120*u^3);
    end quinticKinematics;
  
    function s45Kinematics
      "Ankle first, then knee: archived S45 prescribed-point geometry"
      input Modelica.Units.SI.Position x;
      input Modelica.Units.SI.Length Ls=0.45 "Canonical reduced link, not anthropometry";
      input Modelica.Units.SI.Length Lu=1.15 "Knee to force-point link";
      input Modelica.Units.SI.Angle ankleMax=12*Modelica.Constants.pi/180;
      output Modelica.Units.SI.Angle qa;
      output Modelica.Units.SI.Angle qk;
    protected
      Real arg;
    algorithm
      assert(Ls > 0 and Lu > 0 and x >= 0 and x < Ls+Lu,
        "Invalid S45 geometry/domain");
      assert(ankleMax > 0 and ankleMax < Modelica.Constants.pi/2,
        "Ankle range must lie strictly between zero and pi/2");
      qa := min(asin(x/(Ls+Lu)), ankleMax);
      arg := (x-Ls*sin(qa))/Lu;
      assert(abs(arg) <= 1, "Knee-available geometry infeasible");
      qk := max(asin(arg)-qa, 0);
    end s45Kinematics;
  
    function s46Diagnostics
      "Historical S46 routing diagnostic, not closed Newton-Euler forward dynamics"
      input Modelica.Units.SI.Position x;
      input Modelica.Units.SI.Acceleration a;
      input Real beta(min=0)=0.05 "Resistance / body weight";
      input Modelica.Units.SI.Mass M=75;
      input Modelica.Units.SI.Acceleration g=9.81;
      input Modelica.Units.SI.Length h=1.60;
      input Modelica.Units.SI.Length zCOM=1.02
        "Reconstructed from archived support-force/COP history";
      input Modelica.Units.SI.Position xHeel=-0.09;
      input Modelica.Units.SI.Position xToe=0.15;
      output Modelica.Units.SI.Force upperForce;
      output Modelica.Units.SI.Angle ankleDemand;
      output Modelica.Units.SI.Position copUpper;
      output Modelica.Units.SI.Position copSupport;
      output Real heelDemandUpper "Signed requirement; negative means infeasible";
      output Real heelDemandSupport "Signed requirement; >1 means toe tension needed";
    algorithm
      assert(M > 0 and g > 0 and h > 0 and zCOM > 0 and beta >= 0,
        "Invalid S46 parameters");
      assert(xHeel < 0 and xToe > 0 and x >= 0 and x < h,
        "Invalid S46 contact geometry or inverse-sine domain");
      upperForce := max(M*a + beta*M*g, 0);
      ankleDemand := asin(x/h);
      copUpper := h*upperForce/(M*g);
      copSupport := -zCOM*upperForce/(M*g);
      heelDemandUpper := (xToe-copUpper)/(xToe-xHeel);
      heelDemandSupport := (xToe-copSupport)/(xToe-xHeel);
    end s46Diagnostics;
  
    model S45PrescribedReplay
      "Prescribed kinematic replay; no inertial or muscle dynamics"
      parameter Modelica.Units.SI.Length D=0.4;
      parameter Modelica.Units.SI.Time T=4;
      parameter Modelica.Units.SI.Length Ls=0.45;
      parameter Modelica.Units.SI.Length Lu=1.15;
      parameter Modelica.Units.SI.Angle ankleMax=12*Modelica.Constants.pi/180;
      Modelica.Units.SI.Position x;
      Modelica.Units.SI.Velocity v;
      Modelica.Units.SI.Acceleration a;
      Modelica.Units.SI.Angle qa;
      Modelica.Units.SI.Angle qk;
    equation
      (x,v,a)=quinticKinematics(time,D,T);
      (qa,qk)=s45Kinematics(x,Ls,Lu,ankleMax);
      annotation(experiment(StopTime=4,Interval=0.001,Tolerance=1e-8));
    end S45PrescribedReplay;
  
    model S46PrescribedReplay
      "Prescribed S46 diagnostics; first-sampled-event classification in Python runner"
      parameter Modelica.Units.SI.Length D=0.4;
      parameter Modelica.Units.SI.Time T=4;
      parameter Real beta=0.05;
      parameter Modelica.Units.SI.Angle ankleROM=12*Modelica.Constants.pi/180;
      parameter Modelica.Units.SI.Length h=1.60;
      parameter Modelica.Units.SI.Position xHeel=-0.09;
      parameter Modelica.Units.SI.Position xToe=0.15;
      Modelica.Units.SI.Position x,copUpper,copSupport;
      Modelica.Units.SI.Velocity v;
      Modelica.Units.SI.Acceleration a;
      Modelica.Units.SI.Angle ankleDemand,romMargin;
      Modelica.Units.SI.Force upperForce;
      Real heelDemandUpper,heelDemandSupport;
      Boolean heelBoundaryReached;
      Boolean romBoundaryReached;
    equation
      (x,v,a)=quinticKinematics(time,D,T);
      (upperForce,ankleDemand,copUpper,copSupport,heelDemandUpper,heelDemandSupport)=
        s46Diagnostics(x=x,a=a,beta=beta,h=h,xHeel=xHeel,xToe=xToe);
      romMargin=ankleROM-ankleDemand;
      heelBoundaryReached=copUpper >= xToe;
      romBoundaryReached=romMargin <= 0;
      annotation(experiment(StopTime=4,Interval=0.001,Tolerance=1e-8));
    end S46PrescribedReplay;
  
  end CanonicalReplay;

  package AxialBody
    "Executable pelvis-lumbar-thorax extension; independent hips remain in the lower-body assembly"
    extends Modelica.Icons.Package;

    model PelvicRing
      "Rigid pelvic ring with bilateral hip centres and a lumbosacral reference"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D props;
      parameter SI.Length hipCenterDistance(min=0);
      parameter SI.Length lumbosacralToHipVertical(min=0)
        "Inferior distance from lumbosacral frame to hip-centre level";
      parameter SI.Length displayAP(min=0)=0.18;
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_lumbosacral;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_leftHip;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_rightHip;

      output SI.Force reactionForceAtLumbosacral[3]=frame_lumbosacral.f
        "Flow sign follows Modelica frame convention, resolved in local frame";
      output SI.Torque reactionMomentAtLumbosacral[3]=frame_lumbosacral.t;

    protected
      Modelica.Mechanics.MultiBody.Parts.BodyShape body(
        animation=animation,
        r={0,0,-lumbosacralToHipVertical},
        r_CM=props.rCM,
        m=props.mass,
        I_11=props.I_CM[1,1], I_22=props.I_CM[2,2], I_33=props.I_CM[3,3],
        I_21=props.I_CM[2,1], I_31=props.I_CM[3,1], I_32=props.I_CM[3,2],
        shapeType="box",
        length=max(lumbosacralToHipVertical,1e-4),
        width=max(hipCenterDistance,1e-4),
        height=max(displayAP,1e-4),
        lengthDirection={0,0,-1}, widthDirection={0,1,0});
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation leftHip(
        r={0,0.5*hipCenterDistance,-lumbosacralToHipVertical},animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation rightHip(
        r={0,-0.5*hipCenterDistance,-lumbosacralToHipVertical},animation=false);
    equation
      assert(props.mass>0 and ModelicaHumanBodyPArts.Utilities.physicalInertia(props.I_CM),
        "PelvicRing requires positive mass and a physical COM inertia tensor.");
      connect(frame_lumbosacral,body.frame_a);
      connect(frame_lumbosacral,leftHip.frame_a);
      connect(frame_lumbosacral,rightHip.frame_a);
      connect(leftHip.frame_b,frame_leftHip);
      connect(rightHip.frame_b,frame_rightHip);
      annotation(Documentation(info="<html><p>Baseline anatomical architecture: one mostly rigid pelvic ring, not two freely rotating hemipelves. Small sacroiliac compliance is intentionally deferred to a replaceable sensitivity architecture. The mass tensor is explicit and must not overlap with thorax/abdomen mass partitions.</p></html>"));
    end PelvicRing;

    model LumbarSpine3D
      "Reduced passive 3-DOF lumbosacral joint: flexion, lateral bending, axial rotation"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=3);
      parameter SI.Angle q_start[3]={0,0,0};
      parameter Boolean q_fixed[3]=fill(false,3);
      parameter SI.AngularVelocity w_start[3]=fill(0,3);
      parameter Boolean w_fixed[3]=fill(false,3);
      parameter Real kPassive[3](each unit="N.m/rad")={0,0,0};
      parameter Real cPassive[3](each unit="N.m.s/rad")={0,0,0};
      parameter SI.Angle qNeutral[3]={0,0,0};

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvis;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_thorax;

      output SI.Angle q[3];
      output SI.AngularVelocity w[3];
      output Real limitUtilization[3];
      output SI.Torque passiveTorque[3];
      output SI.Power passivePower;
      output SI.Force pelvisReactionForce[3]=frame_pelvis.f;
      output SI.Torque pelvisReactionMoment[3]=frame_pelvis.t;
      output SI.Force thoraxReactionForce[3]=frame_thorax.f;
      output SI.Torque thoraxReactionMoment[3]=frame_thorax.t;

    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute flexExt(
        n={0,1,0},useAxisFlange=true,
        phi(start=q_start[1],fixed=q_fixed[1]),w(start=w_start[1],fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute lateralBend(
        n={-1,0,0},useAxisFlange=true,
        phi(start=q_start[2],fixed=q_fixed[2]),w(start=w_start[2],fixed=w_fixed[2]));
      Modelica.Mechanics.MultiBody.Joints.Revolute axialRotation(
        n={0,0,1},useAxisFlange=true,
        phi(start=q_start[3],fixed=q_fixed[3]),w(start=w_start[3],fixed=w_fixed[3]));
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveFlex(
        c=kPassive[1],d=cPassive[1],phi_rel0=-qNeutral[1]);
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveBend(
        c=kPassive[2],d=cPassive[2],phi_rel0=-qNeutral[2]);
      Modelica.Mechanics.Rotational.Components.SpringDamper passiveAxial(
        c=kPassive[3],d=cPassive[3],phi_rel0=-qNeutral[3]);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=3,mobility=mobility);
    equation
      connect(frame_pelvis,flexExt.frame_a);
      connect(flexExt.frame_b,lateralBend.frame_a);
      connect(lateralBend.frame_b,axialRotation.frame_a);
      connect(axialRotation.frame_b,frame_thorax);
      connect(flexExt.axis,passiveFlex.flange_a); connect(flexExt.support,passiveFlex.flange_b);
      connect(lateralBend.axis,passiveBend.flange_a); connect(lateralBend.support,passiveBend.flange_b);
      connect(axialRotation.axis,passiveAxial.flange_a); connect(axialRotation.support,passiveAxial.flange_b);
      q={flexExt.phi,lateralBend.phi,axialRotation.phi};
      w={flexExt.w,lateralBend.w,axialRotation.w};
      monitor.q=q;
      limitUtilization=monitor.utilization;
      passiveTorque=-kPassive.*(q-qNeutral)-cPassive.*w;
      passivePower=sum(passiveTorque.*w);
      annotation(Documentation(info="<html><p>Library coordinates are +x anterior, +y left, +z superior. Positive flexion moves the superior trunk anteriorly (+y rotation axis); positive lateral bend moves it leftward (-x axis); positive axial rotation is left yaw (+z axis). No active torque is hidden here. Passive impedance is explicit and separately reported. Landmark-level ISB validation remains required before clinical interpretation.</p></html>"));
    end LumbarSpine3D;

    model Thorax
      "Rigid thoracic segment with lumbar, cervical and bilateral shoulder reference frames"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D props;
      parameter SI.Length shoulderWidth(min=0);
      parameter SI.Length shoulderHeight(min=0)=0.75*props.length;
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_lumbar;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_leftShoulder;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_rightShoulder;

      output SI.Force lumbarReactionForce[3]=frame_lumbar.f;
      output SI.Torque lumbarReactionMoment[3]=frame_lumbar.t;

    protected
      Modelica.Mechanics.MultiBody.Parts.BodyShape body(
        animation=animation,r={0,0,props.length},r_CM=props.rCM,m=props.mass,
        I_11=props.I_CM[1,1],I_22=props.I_CM[2,2],I_33=props.I_CM[3,3],
        I_21=props.I_CM[2,1],I_31=props.I_CM[3,1],I_32=props.I_CM[3,2],
        shapeType="box",length=max(props.length,1e-4),width=max(shoulderWidth,1e-4),height=0.18,
        lengthDirection={0,0,1},widthDirection={0,1,0});
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation leftShoulder(
        r={0,0.5*shoulderWidth,shoulderHeight},animation=false);
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation rightShoulder(
        r={0,-0.5*shoulderWidth,shoulderHeight},animation=false);
    equation
      assert(props.mass>0 and props.length>0 and shoulderHeight>=0 and shoulderHeight<=props.length and
        ModelicaHumanBodyPArts.Utilities.physicalInertia(props.I_CM),
        "Thorax requires positive dimensions/mass and a physical inertia tensor.");
      connect(frame_lumbar,body.frame_a);
      connect(body.frame_b,frame_cervical);
      connect(frame_lumbar,leftShoulder.frame_a); connect(leftShoulder.frame_b,frame_leftShoulder);
      connect(frame_lumbar,rightShoulder.frame_a); connect(rightShoulder.frame_b,frame_rightShoulder);
      annotation(Documentation(info="<html><p>Mass properties are explicit inputs. This component does not silently reuse the old lower-trunk/pelvis proxy. Shoulder/cervical frames are mechanical reference points, not validated anatomical landmarks.</p></html>"));
    end Thorax;

    model PelvisLumbarThorax
      "Rigid pelvic ring + passive 3-DOF lumbar joint + rigid thorax"
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pelvicProps;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D thoraxProps;
      parameter Modelica.Units.SI.Length hipCenterDistance;
      parameter Modelica.Units.SI.Length lumbosacralToHipVertical;
      parameter Modelica.Units.SI.Length shoulderWidth;
      parameter Modelica.Units.SI.Length shoulderHeight=0.75*thoraxProps.length;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarMobility(n=3);
      parameter Modelica.Units.SI.Angle lumbarStart[3]={0,0,0};
      parameter Boolean lumbarFixed[3]=fill(false,3);
      parameter Modelica.Units.SI.AngularVelocity lumbarWStart[3]=fill(0,3);
      parameter Boolean lumbarWFixed[3]=fill(false,3);
      parameter Real lumbarK[3](each unit="N.m/rad")={0,0,0};
      parameter Real lumbarC[3](each unit="N.m.s/rad")={0,0,0};
      parameter Modelica.Units.SI.Angle lumbarNeutral[3]={0,0,0};
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_leftHip;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_rightHip;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_leftShoulder;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_rightShoulder;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisReference;

      output Modelica.Units.SI.Angle lumbarQ[3];
      output Modelica.Units.SI.AngularVelocity lumbarW[3];
      output Modelica.Units.SI.Torque lumbarPassiveTorque[3];
      output Modelica.Units.SI.Power lumbarPassivePower;
      output Modelica.Units.SI.Force lumbosacralForce[3];
      output Modelica.Units.SI.Torque lumbosacralMoment[3];
      output Modelica.Units.SI.Mass representedAxialMass=pelvicProps.mass+thoraxProps.mass;
    protected
      PelvicRing pelvis(props=pelvicProps,hipCenterDistance=hipCenterDistance,
        lumbosacralToHipVertical=lumbosacralToHipVertical,animation=animation);
      LumbarSpine3D lumbar(mobility=lumbarMobility,q_start=lumbarStart,q_fixed=lumbarFixed,
        w_start=lumbarWStart,w_fixed=lumbarWFixed,kPassive=lumbarK,cPassive=lumbarC,qNeutral=lumbarNeutral);
      Thorax thorax(props=thoraxProps,shoulderWidth=shoulderWidth,shoulderHeight=shoulderHeight,animation=animation);
    equation
      connect(frame_pelvisReference,pelvis.frame_lumbosacral);
      connect(pelvis.frame_lumbosacral,lumbar.frame_pelvis);
      connect(lumbar.frame_thorax,thorax.frame_lumbar);
      connect(pelvis.frame_leftHip,frame_leftHip); connect(pelvis.frame_rightHip,frame_rightHip);
      connect(thorax.frame_cervical,frame_cervical);
      connect(thorax.frame_leftShoulder,frame_leftShoulder); connect(thorax.frame_rightShoulder,frame_rightShoulder);
      lumbarQ=lumbar.q; lumbarW=lumbar.w; lumbarPassiveTorque=lumbar.passiveTorque;
      lumbarPassivePower=lumbar.passivePower;
      lumbosacralForce=lumbar.pelvisReactionForce; lumbosacralMoment=lumbar.pelvisReactionMoment;
    end PelvisLumbarThorax;

    model LowerBodyAxialAssembly
      "Bilateral legs connected to the new rigid pelvic ring and articulated lumbar/thorax chain"
      import SI=Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pelvicProps;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D thoraxProps;
      parameter SI.Length lumbosacralToHipVertical;
      parameter SI.Length shoulderWidth;
      parameter SI.Length shoulderHeight=0.75*thoraxProps.length;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarMobility(n=3);
      parameter Boolean fixInitialJointCoordinates=false;
      parameter Boolean fixInitialJointVelocities=false;
      parameter SI.Angle leftHipStart[3]=zeros(3),rightHipStart[3]=zeros(3);
      parameter SI.Angle leftKneeStart=0,rightKneeStart=0;
      parameter SI.Angle leftAnkleStart[2]=zeros(2),rightAnkleStart[2]=zeros(2);
      parameter SI.Angle lumbarStart[3]=zeros(3);
      parameter Boolean lumbarFixed[3]=fill(false,3);
      parameter SI.AngularVelocity lumbarWStart[3]=zeros(3);
      parameter Boolean lumbarWFixed[3]=fill(false,3);
      parameter Real hipK[3](each unit="N.m/rad")={0,0,0};
      parameter Real hipC[3](each unit="N.m.s/rad")={0,0,0};
      parameter SI.Angle hipNeutral[3]={0,0,0};
      parameter Real lumbarK[3](each unit="N.m/rad")={0,0,0};
      parameter Real lumbarC[3](each unit="N.m.s/rad")={0,0,0};
      parameter SI.Length footCOMAboveSole=0;
      parameter String footCOMOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE";
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisReference;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b rightPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftFootReference;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b rightFootReference;

      output SI.Mass representedMass;
      output SI.Angle leftQ[6],rightQ[6],lumbarQ[3];
      output SI.Force leftHipReactionForce[3],rightHipReactionForce[3];
      output SI.Torque leftHipReactionMoment[3],rightHipReactionMoment[3];
      output SI.Force leftKneeReactionForce[3],rightKneeReactionForce[3];
      output SI.Torque leftKneeReactionMoment[3],rightKneeReactionMoment[3];
      output SI.Force leftAnkleReactionForce[3],rightAnkleReactionForce[3];
      output SI.Torque leftAnkleReactionMoment[3],rightAnkleReactionMoment[3];
      output SI.Force lumbosacralForce[3];
      output SI.Torque lumbosacralMoment[3];
      output SI.Power lumbarPassivePower;

    protected
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      PelvisLumbarThorax axial(pelvicProps=pelvicProps,thoraxProps=thoraxProps,
        hipCenterDistance=profile.hipCenterDistance,lumbosacralToHipVertical=lumbosacralToHipVertical,
        shoulderWidth=shoulderWidth,shoulderHeight=shoulderHeight,lumbarMobility=lumbarMobility,
        lumbarStart=lumbarStart,lumbarFixed=lumbarFixed,lumbarWStart=lumbarWStart,lumbarWFixed=lumbarWFixed,
        lumbarK=lumbarK,lumbarC=lumbarC,animation=animation);
      ModelicaHumanBodyPArts.Joints.Hip leftHip(mobility=hipMobility,isLeft=true,q_start=leftHipStart,
        q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),
        kPassive=hipK,cPassive=hipC,qNeutral=hipNeutral);
      ModelicaHumanBodyPArts.Segments.Thigh leftThigh(props=thighProps,animation=animation);
      ModelicaHumanBodyPArts.Joints.Knee leftKnee(mobility=kneeMobility,phi_start=leftKneeStart,
        phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities);
      ModelicaHumanBodyPArts.Segments.Shank leftShank(props=shankProps,animation=animation);
      ModelicaHumanBodyPArts.Joints.AnkleComplex leftAnkle(mobility=ankleMobility,isLeft=true,q_start=leftAnkleStart,
        q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2));
      ModelicaHumanBodyPArts.Segments.Foot leftFoot(props=footProps,footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,
        comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=true);
      ModelicaHumanBodyPArts.Joints.Hip rightHip(mobility=hipMobility,isLeft=false,q_start=rightHipStart,
        q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),
        kPassive=hipK,cPassive=hipC,qNeutral=hipNeutral);
      ModelicaHumanBodyPArts.Segments.Thigh rightThigh(props=thighProps,animation=animation);
      ModelicaHumanBodyPArts.Joints.Knee rightKnee(mobility=kneeMobility,phi_start=rightKneeStart,
        phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities);
      ModelicaHumanBodyPArts.Segments.Shank rightShank(props=shankProps,animation=animation);
      ModelicaHumanBodyPArts.Joints.AnkleComplex rightAnkle(mobility=ankleMobility,isLeft=false,q_start=rightAnkleStart,
        q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2));
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(props=footProps,footWidth=profile.footWidth,
        ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,
        comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=false);
    equation
      connect(frame_pelvisReference,axial.frame_pelvisReference); connect(axial.frame_cervical,frame_cervical);
      connect(axial.frame_leftHip,leftHip.frame_a); connect(leftHip.frame_b,leftThigh.frame_proximal);
      connect(leftThigh.frame_distal,leftKnee.frame_a); connect(leftKnee.frame_b,leftShank.frame_proximal);
      connect(leftShank.frame_distal,leftAnkle.frame_a); connect(leftAnkle.frame_b,leftFoot.frame_ankle);
      connect(leftFoot.frame_ankle,leftFootReference);
      connect(axial.frame_rightHip,rightHip.frame_a); connect(rightHip.frame_b,rightThigh.frame_proximal);
      connect(rightThigh.frame_distal,rightKnee.frame_a); connect(rightKnee.frame_b,rightShank.frame_proximal);
      connect(rightShank.frame_distal,rightAnkle.frame_a); connect(rightAnkle.frame_b,rightFoot.frame_ankle);
      connect(rightFoot.frame_ankle,rightFootReference);
      for i in 1:6 loop
        connect(leftFoot.frame_plantar[i],leftPlantarFrames[i]); connect(rightFoot.frame_plantar[i],rightPlantarFrames[i]);
      end for;
      leftQ=cat(1,leftHip.q,{leftKnee.q},leftAnkle.q); rightQ=cat(1,rightHip.q,{rightKnee.q},rightAnkle.q);
      lumbarQ=axial.lumbarQ;
      representedMass=pelvicProps.mass+thoraxProps.mass+2*(thighProps.mass+shankProps.mass+footProps.mass);
      leftHipReactionForce=leftHip.frame_a.f; rightHipReactionForce=rightHip.frame_a.f;
      leftHipReactionMoment=leftHip.frame_a.t; rightHipReactionMoment=rightHip.frame_a.t;
      leftKneeReactionForce=leftKnee.frame_a.f; rightKneeReactionForce=rightKnee.frame_a.f;
      leftKneeReactionMoment=leftKnee.frame_a.t; rightKneeReactionMoment=rightKnee.frame_a.t;
      leftAnkleReactionForce=leftAnkle.frame_a.f; rightAnkleReactionForce=rightAnkle.frame_a.f;
      leftAnkleReactionMoment=leftAnkle.frame_a.t; rightAnkleReactionMoment=rightAnkle.frame_a.t;
      lumbosacralForce=axial.lumbosacralForce; lumbosacralMoment=axial.lumbosacralMoment;
      lumbarPassivePower=axial.lumbarPassivePower;
      annotation(Documentation(info="<html><p>This assembly replaces the old pelvis/lower-trunk proxy with explicit pelvic-ring and thorax mass tensors separated by a 3-DOF lumbar joint. It does not yet generate those axial mass properties from stature; they are explicit source-traceable inputs.</p></html>"));
    end LowerBodyAxialAssembly;

    model LowerBodyAxialGroundedAssembly
      "Axial-body lower-body assembly with two six-zone plantar contacts"
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pelvicProps;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D thoraxProps;
      parameter Modelica.Units.SI.Length lumbosacralToHipVertical;
      parameter Modelica.Units.SI.Length shoulderWidth;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarMobility(n=3);
      parameter Real hipK[3](each unit="N.m/rad")={0,0,0};
      parameter Real hipC[3](each unit="N.m.s/rad")={0,0,0};
      parameter Modelica.Units.SI.Angle hipNeutral[3]={0,0,0};
      parameter Real lumbarK[3](each unit="N.m/rad")={0,0,0};
      parameter Real lumbarC[3](each unit="N.m.s/rad")={0,0,0};
      parameter Modelica.Units.SI.Position groundHeight=0;
      parameter Real kNormal(unit="N/m")=2e5;
      parameter Real cNormal(unit="N.s/m")=500;
      parameter Real mu(min=0)=0.7;
      parameter Modelica.Units.SI.Velocity vSlip=0.01;
      parameter Real torsionalFrictionFactor(min=0,max=1)=0;
      parameter Modelica.Units.SI.AngularVelocity omegaTorsionSlip=0.05;
      parameter Modelica.Units.SI.Length patchRadius[6]=fill(0,6);

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisReference;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      output Modelica.Units.SI.Force leftGRF[3],rightGRF[3];
      output Modelica.Units.SI.Torque leftGroundMoment[3],rightGroundMoment[3];
      output Modelica.Units.SI.Position leftCOP[2],rightCOP[2];
      output Boolean leftCOPValid,rightCOPValid;
      output Modelica.Units.SI.Angle leftQ[6],rightQ[6],lumbarQ[3];
      output Modelica.Units.SI.Mass representedMass;
      output Modelica.Units.SI.Force leftHipReactionForce[3],rightHipReactionForce[3];
      output Modelica.Units.SI.Torque leftHipReactionMoment[3],rightHipReactionMoment[3];
      output Modelica.Units.SI.Torque lumbosacralMoment[3];
    protected
      LowerBodyAxialAssembly body(profile=profile,pelvicProps=pelvicProps,thoraxProps=thoraxProps,
        lumbosacralToHipVertical=lumbosacralToHipVertical,shoulderWidth=shoulderWidth,
        hipMobility=hipMobility,kneeMobility=kneeMobility,ankleMobility=ankleMobility,
        lumbarMobility=lumbarMobility,hipK=hipK,hipC=hipC,hipNeutral=hipNeutral,lumbarK=lumbarK,lumbarC=lumbarC);
      ModelicaHumanBodyPArts.Contact.PlantarContact leftContact(groundHeight=groundHeight,kNormal=kNormal,
        cNormal=cNormal,mu=mu,vSlip=vSlip,torsionalFrictionFactor=torsionalFrictionFactor,
        omegaTorsionSlip=omegaTorsionSlip,patchRadius=patchRadius);
      ModelicaHumanBodyPArts.Contact.PlantarContact rightContact(groundHeight=groundHeight,kNormal=kNormal,
        cNormal=cNormal,mu=mu,vSlip=vSlip,torsionalFrictionFactor=torsionalFrictionFactor,
        omegaTorsionSlip=omegaTorsionSlip,patchRadius=patchRadius);
    equation
      connect(frame_pelvisReference,body.frame_pelvisReference); connect(body.frame_cervical,frame_cervical);
      connect(body.leftFootReference,leftContact.frame_torsion); connect(body.rightFootReference,rightContact.frame_torsion);
      for i in 1:6 loop
        connect(body.leftPlantarFrames[i],leftContact.plantarFrames[i]); connect(body.rightPlantarFrames[i],rightContact.plantarFrames[i]);
      end for;
      leftGRF=leftContact.groundReactionForce; rightGRF=rightContact.groundReactionForce;
      leftGroundMoment=leftContact.groundMoment; rightGroundMoment=rightContact.groundMoment;
      leftCOP=leftContact.cop; rightCOP=rightContact.cop; leftCOPValid=leftContact.copValid; rightCOPValid=rightContact.copValid;
      leftQ=body.leftQ; rightQ=body.rightQ; lumbarQ=body.lumbarQ; representedMass=body.representedMass;
      leftHipReactionForce=body.leftHipReactionForce; rightHipReactionForce=body.rightHipReactionForce;
      leftHipReactionMoment=body.leftHipReactionMoment; rightHipReactionMoment=body.rightHipReactionMoment;
      lumbosacralMoment=body.lumbosacralMoment;
    end LowerBodyAxialGroundedAssembly;

    model PelvicRingGeometryTest
      "Synthetic geometry regression for rigid pelvic ring and bilateral hip frames"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D p(mass=8,length=0.18,rCM={0,0,-0.05},
        I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor(r={0,0,1.1},animation=false);
      PelvicRing pelvis(props=p,hipCenterDistance=0.20,lumbosacralToHipVertical=0.10,animation=false);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition leftPos(resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      Modelica.Mechanics.MultiBody.Sensors.AbsolutePosition rightPos(resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameA.world);
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.009;
    equation
      connect(anchor.frame_b,pelvis.frame_lumbosacral); connect(pelvis.frame_leftHip,leftPos.frame_a); connect(pelvis.frame_rightHip,rightPos.frame_a);
    algorithm
      when time>=verificationTime then
        assert(abs(leftPos.r[2]-0.10)<1e-10 and abs(rightPos.r[2]+0.10)<1e-10,"Pelvic hip lateral symmetry failed");
        assert(abs(leftPos.r[3]-1.0)<1e-10 and abs(rightPos.r[3]-1.0)<1e-10,"Pelvic hip level failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end PelvicRingGeometryTest;

    model LumbarAxisGeometryTest
      "Independent prescribed-axis geometry check for the three lumbar coordinates"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter Real cases[3,3]={{0.15,0,0},{0,0.15,0},{0,0,0.15}};
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor[3](each r={0,0,1},each animation=false);
      LumbarSpine3D lumbar[3](each mobility=rom,q_start=cases,
        each q_fixed={true,true,true},each w_fixed={true,true,true});
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation marker[3](each r={0.10,0,0.40},each animation=false);
      Modelica.Mechanics.MultiBody.Parts.Body testInertia[3](each animation=false,
        each m=1,each r_CM={0,0,0},each I_11=0.01,each I_22=0.01,each I_33=0.01)
        "Finite inertial fixture removes the massless zero-impedance indeterminacy";
      output Real observed[3,3];
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.009;
    equation
      for i in 1:3 loop
        connect(anchor[i].frame_b,lumbar[i].frame_pelvis); connect(lumbar[i].frame_thorax,marker[i].frame_a);
        connect(marker[i].frame_b,testInertia[i].frame_a);
        observed[i,:]=marker[i].frame_b.r_0-anchor[i].r;
      end for;
    algorithm
      when time>=verificationTime then
        assert(observed[1,1]>0.10,"Positive lumbar flexion must move superior marker anteriorly");
        assert(observed[2,2]>0,"Positive lateral bend must move superior marker leftward");
        assert(observed[3,2]>0,"Positive axial rotation must rotate anterior marker toward leftward +y");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end LumbarAxisGeometryTest;

    model AxialMassPartitionTest
      "Synthetic check that pelvis and thorax masses are distinct and counted once"
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,rCM={0,0,-0.05},I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.50,rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1.0}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      output Modelica.Units.SI.Mass axialMass=pp.mass+tp.mass;
      output Integer checksPassed(start=0,fixed=true);
      parameter Modelica.Units.SI.Time verificationTime=0.009;
    algorithm
      when time>=verificationTime then
        assert(abs(axialMass-33)<1e-12,"Axial mass partition double-count/missing-mass test failed"); checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-9));
    end AxialMassPartitionTest;

    model LumbarPassiveDissipationTest
      "Synthetic passive axial-rotation decay; verifies no hidden propulsive torque"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=10,length=0.40,rCM={0,0,0.20},I_CM={{0.5,0,0},{0,0.5,0},{0,0,0.25}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      Modelica.Mechanics.MultiBody.Parts.Fixed base(animation=false);
      LumbarSpine3D lumbar(mobility=rom,q_start={0,0,0.20},q_fixed={true,true,true},w_start={0,0,0},w_fixed={true,true,true},kPassive={0,0,20},cPassive={0,0,1});
      Thorax thorax(props=tp,shoulderWidth=0.40,animation=false);
      output SI.Angle axialAngle=lumbar.q[3];
      output SI.Power passivePower=lumbar.passivePower;
      output Integer checksPassed(start=0,fixed=true);
      parameter SI.Time verificationTime=1.0;
    equation
      connect(base.frame_b,lumbar.frame_pelvis); connect(lumbar.frame_thorax,thorax.frame_lumbar);
    algorithm
      when time>=verificationTime then
        assert(abs(axialAngle)<0.20,"Passive lumbar spring/damper did not reduce initial axial displacement");
        assert(passivePower<=1e-6,"Passive lumbar element generated positive mechanical power at verification time");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1.1,Tolerance=1e-8,Interval=0.001));
    end LumbarPassiveDissipationTest;

    model LowerBodyAxialAssemblyBuild
      "Build-only fixture for the new axial lower-body architecture"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.18,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,rCM={0,0,-0.05},I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.50,rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1.0}},R_principal=identity(3),segmentFrameId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_AXIAL_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin={-0.5,-0.5,-0.5},qMax={0.5,0.5,0.5},sourceId="SYNTHETIC_AXIAL_TEST");
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor(r={0,0,1.1},animation=false);
      LowerBodyAxialAssembly body(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.10,shoulderWidth=0.40,
        hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},animation=false);
    equation
      connect(anchor.frame_b,body.frame_pelvisReference);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end LowerBodyAxialAssemblyBuild;


    model StandingLegRotationalTransmissionTest
      "External standing-foot yaw torque; pelvis/lumbar/free-hip responses are outputs, not prescribed"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(
        height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,
        footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,
        shankLength=0.43,thighLength=0.44,pelvisLength=0.18,hipCenterDistance=0.20,
        geometrySourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(
        mass=8,length=0.18,rCM={0,0,-0.05},
        I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),
        segmentFrameId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(
        mass=25,length=0.50,rCM={0,0,0.25},
        I_CM={{1.2,0,0},{0,0.9,0},{0,0,1.0}},R_principal=identity(3),
        segmentFrameId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(
        n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(
        n=1,qMin={-1},qMax={2.8},sourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(
        n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(
        n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SYNTHETIC_ROTATIONAL_TRANSMISSION_TEST");
      Modelica.Mechanics.MultiBody.Parts.Fixed ground(animation=false);
      Modelica.Mechanics.MultiBody.Joints.Revolute standingYaw(
        n={0,0,1},useAxisFlange=true,phi(start=0,fixed=true),w(start=0,fixed=true));
      Modelica.Mechanics.Rotational.Sources.Torque torqueSource(useSupport=true);
      LowerBodyAxialAssembly body(
        profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.10,shoulderWidth=0.40,
        hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,
        hipK={0,0,25},hipC={0,0,1.2},lumbarK={0,0,15},lumbarC={0,0,0.8},
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
        lumbarFixed={true,true,true},lumbarWFixed={true,true,true},animation=false);
      output SI.Torque appliedGroundTorque;
      output SI.Angle standingFootYaw=standingYaw.phi;
      output SI.Angle standingHipAxial=body.leftQ[3];
      output SI.Angle freeHipAxial=body.rightQ[3];
      output SI.Angle pelvisYawProxy=standingFootYaw+standingHipAxial
        "Exact for the test's axial chain because ankle/knee have no yaw DOF";
      output SI.Angle lumbarAxial=body.lumbarQ[3];
      output SI.Angle thoraxYawProxy=pelvisYawProxy+lumbarAxial;
      output SI.Torque standingHipReactionYaw=body.leftHipReactionMoment[3];
      output SI.Torque lumbosacralReactionYaw=body.lumbosacralMoment[3];
      output Integer checksPassed(start=0,fixed=true);
      parameter SI.Time verificationTime=0.45;
    equation
      connect(ground.frame_b,standingYaw.frame_a);
      connect(standingYaw.frame_b,body.leftPlantarFrames[1]);
      connect(torqueSource.flange,standingYaw.axis);
      connect(torqueSource.support,standingYaw.support);
      appliedGroundTorque=if time<0.05 then 0 else if time<0.25 then 5 else 0;
      torqueSource.tau=appliedGroundTorque;
    algorithm
      when time>=verificationTime then
        assert(abs(standingFootYaw)>1e-6,"Standing-foot yaw did not respond to the external torque.");
        assert(abs(pelvisYawProxy)>1e-6,"No rotational response reached the pelvis proxy.");
        assert(abs(lumbarAxial)>1e-7,"No rotational response reached the lumbar coordinate.");
        assert(abs(freeHipAxial)>1e-7,"No rotational response reached the opposite/free hip.");
        checksPassed:=1;
      end when;
      annotation(Documentation(info="<html><p>This is a synthetic mechanical transmission test, not a Lynkorr proof. The only imposed rotational mission profile is the standing-foot external torque. Pelvis proxy, lumbar axial rotation and opposite-hip rotation are measured outputs. The signs/magnitudes are not prescribed and must not be interpreted as human data because the passive stiffness/damping values and axial mass tensors are synthetic.</p></html>"),
        experiment(StartTime=0,StopTime=0.5,Tolerance=1e-8,Interval=0.0005));
    end StandingLegRotationalTransmissionTest;

  end AxialBody;



  package Transmission
    "Mechanical transmission, variable impedance and load-exposure diagnostics"
    extends Modelica.Icons.Package;

    model VariableImpedance1D
      "Variable rotational impedance with an explicit modulation-energy port"
      import SI = Modelica.Units.SI;
      extends Modelica.Mechanics.Rotational.Interfaces.PartialCompliantWithRelativeStates;
      parameter SI.RotationalSpringConstant kBase(min=0)=0;
      parameter SI.RotationalDampingConstant cBase(min=0)=0;
      parameter SI.Angle qNeutral=0 "Constant neutral joint angle; q=-phi_rel";
      parameter Real rateTolerance(unit="1/s")=1e-7;
      input Real stiffnessScale(min=0);
      input Real dampingScale(min=0);
      input Real stiffnessScaleRate(unit="1/s");
      output SI.Torque restoringTorque;
      output SI.Energy elasticEnergy;
      output SI.Power mechanicalPowerIntoElement;
      output SI.Power dampingDissipationPower;
      output SI.Power modulationPowerIntoStorage
        "Positive when modulation adds elastic storage at fixed deformation";
      output SI.Power stiffnessModulationPowerToMechanical
        "Legacy opposite-sign alias; NOT extra torque-times-speed joint power";
      output SI.Power energyBalanceResidual;
      output Real scaleRateResidual(unit="1/s");
    protected
      SI.Angle q;
      SI.AngularVelocity qd;
    equation
      assert(kBase>=0 and cBase>=0 and stiffnessScale>=0 and dampingScale>=0,
        "Impedance coefficients must be nonnegative.");
      q=-phi_rel;
      qd=-w_rel;
      tau=-kBase*stiffnessScale*(q-qNeutral)-cBase*dampingScale*qd;
      restoringTorque=tau;
      elasticEnergy=0.5*kBase*stiffnessScale*(q-qNeutral)^2;
      mechanicalPowerIntoElement=tau*w_rel;
      dampingDissipationPower=cBase*dampingScale*qd^2;
      modulationPowerIntoStorage=0.5*kBase*der(stiffnessScale)*(q-qNeutral)^2;
      stiffnessModulationPowerToMechanical=-modulationPowerIntoStorage;
      scaleRateResidual=stiffnessScaleRate-der(stiffnessScale);
      assert(noEvent(abs(scaleRateResidual)<=rateTolerance*(1+abs(stiffnessScaleRate))),
        "Supplied stiffnessScaleRate disagrees with the actual schedule derivative.");
      energyBalanceResidual=der(elasticEnergy)-mechanicalPowerIntoElement
        +dampingDissipationPower-modulationPowerIntoStorage;
      annotation(Documentation(info="<html><p>New engineering derivation: Udot = Pin - D + Pmod. Modulation is a separate energy exchange; a positive spring-return power is not a violation of passivity. Neutral position is constant. This is not a physiological breathing or muscle model. Continuous differentiable schedules are required.</p></html>"));
    end VariableImpedance1D;

    block SmoothImpedanceSchedule
      "Smooth preparation then release schedule; mechanical surrogate, not respiratory physiology"
      parameter Modelica.Units.SI.Time preparationEnd=0.05;
      parameter Modelica.Units.SI.Time releaseEnd=0.25;
      parameter Real initialScale(min=0)=1;
      parameter Real preparationScale(min=0)=1.2;
      parameter Real releaseScale(min=0)=0.45;
      output Real scale;
      output Real scaleRate(unit="1/s");
    protected
      Real u;
      Real s;
      Real dsdu;
    equation
      assert(preparationEnd>0 and releaseEnd>preparationEnd,"Require 0 < preparationEnd < releaseEnd");
      if time < preparationEnd then
        u=time/preparationEnd;
        s=10*u^3-15*u^4+6*u^5;
        dsdu=30*u^2-60*u^3+30*u^4;
        scale=initialScale+(preparationScale-initialScale)*s;
        scaleRate=(preparationScale-initialScale)*dsdu/preparationEnd;
      elseif time < releaseEnd then
        u=(time-preparationEnd)/(releaseEnd-preparationEnd);
        s=10*u^3-15*u^4+6*u^5;
        dsdu=30*u^2-60*u^3+30*u^4;
        scale=preparationScale+(releaseScale-preparationScale)*s;
        scaleRate=(releaseScale-preparationScale)*dsdu/(releaseEnd-preparationEnd);
      else
        u=1;
        s=1;
        dsdu=0;
        scale=releaseScale;
        scaleRate=0;
      end if;
      annotation(Documentation(info="<html><p>The schedule is deliberately generic. In Lynkorr studies it may be used as a breathing-linked impedance surrogate, but it does not model diaphragm motion, intra-abdominal pressure, EMG, muscle activation or respiratory gas mechanics.</p></html>"));
    end SmoothImpedanceSchedule;

    model InterfaceLoadMetrics
      "Wrench magnitudes, generalized power and convention-dependent load-exposure diagnostics"
      import SI = Modelica.Units.SI;
      parameter Integer n(min=1)=1;
      parameter SI.Mass declaredBodyMass(min=Modelica.Constants.small)=75;
      input SI.Mass representedMass(min=Modelica.Constants.small)=declaredBodyMass;
      parameter SI.Acceleration g=9.81;
      parameter SI.Force forceRegularization=1e-9;
      parameter SI.Torque momentRegularization=1e-9;
      parameter SI.AngularVelocity omegaEps=1e-3;
      input SI.Force force[3];
      input SI.Torque moment[3];
      input SI.Torque generalizedTorque[n];
      input SI.AngularVelocity generalizedSpeed[n];
      output SI.Force forceNorm;
      output Real forcePerDeclaredBW;
      output Real forcePerRepresentedWeight;
      output SI.Torque momentNorm;
      output SI.Power generalizedPower;
      output SI.AngularVelocity speedNorm;
      output Real highLoadLowMotionRatio(unit="N.m.s/rad");
      output Real forceLoadingRate(unit="N/s");
      output Real momentLoadingRate(unit="N.m/s");
      output Real forceImpulse(unit="N.s",start=0,fixed=true);
      output Real momentImpulse(unit="N.m.s",start=0,fixed=true);
      output Real forceVectorIntegral[3](each unit="N.s",each start=0,each fixed=true)
        "Vector impulse only when force components use one fixed reporting frame";
      output Real momentVectorIntegral[3](each unit="N.m.s",each start=0,each fixed=true)
        "Angular impulse only for a fixed reference point and frame";
      output SI.Energy positiveWork(start=0,fixed=true);
      output SI.Energy negativeWork(start=0,fixed=true)
        "Negative generalized work magnitude; includes possible elastic storage, not just heat";
    equation
      forceNorm=sqrt(sum(force.^2)+forceRegularization^2)-forceRegularization;
      momentNorm=sqrt(sum(moment.^2)+momentRegularization^2)-momentRegularization;
      forcePerDeclaredBW=forceNorm/(declaredBodyMass*g);
      forcePerRepresentedWeight=forceNorm/(representedMass*g);
      generalizedPower=sum(generalizedTorque.*generalizedSpeed);
      speedNorm=sqrt(sum(generalizedSpeed.^2));
      highLoadLowMotionRatio=momentNorm/(speedNorm+omegaEps);
      forceLoadingRate=der(forceNorm);
      momentLoadingRate=der(momentNorm);
      assert(declaredBodyMass>0 and representedMass>0 and g>0 and omegaEps>0,
        "Normalization masses, g and speed regularizer must be positive.");
      der(forceVectorIntegral)=force;
      der(momentVectorIntegral)=moment;
      der(forceImpulse)=forceNorm;
      der(momentImpulse)=momentNorm;
      der(positiveWork)=max(generalizedPower,0);
      der(negativeWork)=max(-generalizedPower,0);
      annotation(Documentation(info="<html><p>The highLoadLowMotionRatio is an engineering diagnostic only. It is not a validated biological blocking index, injury predictor or cartilage-stress measure. Force/moment magnitudes are cut reactions at the specified origin. The legacy impulse scalars integrate magnitudes and do not equal vector momentum change. Joint-coordinate speed norm and the ratio are coordinate-convention dependent. Analytic rates exclude discontinuous jumps and are not finite impact/shock measures. Negative generalized work is not automatically dissipation.</p></html>"));
    end InterfaceLoadMetrics;

    model KinematicSmoothnessMetrics
      "Acceleration and jerk exposure for a supplied point/COM acceleration signal"
      import SI = Modelica.Units.SI;
      input SI.Acceleration acceleration[3];
      output Real accelerationNorm(unit="m/s2");
      output Real jerk[3](each unit="m/s3");
      output Real jerkNorm(unit="m/s3");
      output Real jerkExposure(unit="m/s2",start=0,fixed=true);
    equation
      accelerationNorm=sqrt(sum(acceleration.^2));
      jerk=der(acceleration);
      jerkNorm=sqrt(sum(jerk.^2));
      der(jerkExposure)=jerkNorm;
    end KinematicSmoothnessMetrics;

    model Knee
      "1-DOF knee with variable passive impedance and complete cut-wrench diagnostics"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=1);
      parameter SI.Angle phi_start=0;
      parameter Boolean phi_fixed=false;
      parameter SI.AngularVelocity w_start=0;
      parameter Boolean w_fixed=false;
      parameter SI.RotationalSpringConstant kBase=0;
      parameter SI.RotationalDampingConstant cBase=0;
      parameter SI.Angle qNeutral=0;
      input Real stiffnessScale(min=0);
      input Real dampingScale(min=0);
      input Real stiffnessScaleRate(unit="1/s");
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b;
      output SI.Angle q;
      output SI.AngularVelocity w;
      output Real limitUtilization;
      output SI.Force reactionForce[3]=frame_a.f;
      output SI.Torque reactionMoment[3]=frame_a.t;
      output SI.Torque generalizedTorque;
      output SI.Power generalizedPower;
      output SI.Power stiffnessModulationPower;
      output SI.Force cutForceWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.f);
      output SI.Torque cutMomentWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.t);
      output SI.Power cutPowerIntoA=frame_a.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_a.R,der(frame_a.r_0))
        +frame_a.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_a.R);
      output SI.Power cutPowerIntoB=frame_b.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_b.R,der(frame_b.r_0))
        +frame_b.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_b.R);
      output SI.Power powerToDistalBody=-cutPowerIntoB;
      output SI.Power cutPowerClosure=cutPowerIntoA+cutPowerIntoB+generalizedPower
        "Zero for a massless coincident-center joint with the declared torque sign";
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute rev(n={0,1,0},useAxisFlange=true,
        phi(start=phi_start,fixed=phi_fixed),w(start=w_start,fixed=w_fixed));
      VariableImpedance1D impedance(kBase=kBase,cBase=cBase,qNeutral=qNeutral);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=1,mobility=mobility);
    equation
      connect(frame_a,rev.frame_a); connect(rev.frame_b,frame_b);
      connect(rev.axis,impedance.flange_a); connect(rev.support,impedance.flange_b);
      impedance.stiffnessScale=stiffnessScale; impedance.dampingScale=dampingScale;
      impedance.stiffnessScaleRate=stiffnessScaleRate;
      q=rev.phi; w=rev.w; monitor.q={q}; limitUtilization=monitor.utilization[1];
      generalizedTorque=rev.tau; generalizedPower=generalizedTorque*w;
      stiffnessModulationPower=impedance.stiffnessModulationPowerToMechanical;
    end Knee;

    model AnkleComplex
      "2-DOF ankle with variable passive impedance and complete cut-wrench diagnostics"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=2);
      parameter SI.Angle q_start[2]={0,0};
      parameter Boolean q_fixed[2]=fill(false,2);
      parameter SI.AngularVelocity w_start[2]=fill(0,2);
      parameter Boolean w_fixed[2]=fill(false,2);
      parameter Boolean isLeft=true;
      parameter SI.RotationalSpringConstant kBase[2]={0,0};
      parameter SI.RotationalDampingConstant cBase[2]={0,0};
      parameter SI.Angle qNeutral[2]={0,0};
      input Real stiffnessScale[2];
      input Real dampingScale[2];
      input Real stiffnessScaleRate[2](each unit="1/s");
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b;
      output SI.Angle q[2]; output SI.AngularVelocity w[2];
      output Real limitUtilization[2];
      output SI.Force reactionForce[3]=frame_a.f;
      output SI.Torque reactionMoment[3]=frame_a.t;
      output SI.Torque generalizedTorque[2];
      output SI.Power generalizedPower;
      output SI.Power stiffnessModulationPower;
      output SI.Force cutForceWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.f);
      output SI.Torque cutMomentWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.t);
      output SI.Power cutPowerIntoA=frame_a.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_a.R,der(frame_a.r_0))
        +frame_a.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_a.R);
      output SI.Power cutPowerIntoB=frame_b.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_b.R,der(frame_b.r_0))
        +frame_b.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_b.R);
      output SI.Power powerToDistalBody=-cutPowerIntoB;
      output SI.Power cutPowerClosure=cutPowerIntoA+cutPowerIntoB+generalizedPower
        "Zero for a massless coincident-center joint with the declared torque sign";
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute dorsiPlantar(n={0,-1,0},useAxisFlange=true,
        phi(start=q_start[1],fixed=q_fixed[1]),w(start=w_start[1],fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute inversionEversion(
        n=if isLeft then {-1,0,0} else {1,0,0},useAxisFlange=true,
        phi(start=q_start[2],fixed=q_fixed[2]),w(start=w_start[2],fixed=w_fixed[2]));
      VariableImpedance1D imp1(kBase=kBase[1],cBase=cBase[1],qNeutral=qNeutral[1]);
      VariableImpedance1D imp2(kBase=kBase[2],cBase=cBase[2],qNeutral=qNeutral[2]);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=2,mobility=mobility);
    equation
      connect(frame_a,dorsiPlantar.frame_a); connect(dorsiPlantar.frame_b,inversionEversion.frame_a);
      connect(inversionEversion.frame_b,frame_b);
      connect(dorsiPlantar.axis,imp1.flange_a); connect(dorsiPlantar.support,imp1.flange_b);
      connect(inversionEversion.axis,imp2.flange_a); connect(inversionEversion.support,imp2.flange_b);
      imp1.stiffnessScale=stiffnessScale[1]; imp1.dampingScale=dampingScale[1]; imp1.stiffnessScaleRate=stiffnessScaleRate[1];
      imp2.stiffnessScale=stiffnessScale[2]; imp2.dampingScale=dampingScale[2]; imp2.stiffnessScaleRate=stiffnessScaleRate[2];
      q={dorsiPlantar.phi,inversionEversion.phi}; w={dorsiPlantar.w,inversionEversion.w};
      monitor.q=q; limitUtilization=monitor.utilization;
      generalizedTorque={dorsiPlantar.tau,inversionEversion.tau};
      generalizedPower=sum(generalizedTorque.*w);
      stiffnessModulationPower=imp1.stiffnessModulationPowerToMechanical+imp2.stiffnessModulationPowerToMechanical;
    end AnkleComplex;

    model Hip
      "3-DOF hip with variable passive impedance and complete cut-wrench diagnostics"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=3);
      parameter SI.Angle q_start[3]={0,0,0};
      parameter Boolean q_fixed[3]=fill(false,3);
      parameter SI.AngularVelocity w_start[3]=fill(0,3);
      parameter Boolean w_fixed[3]=fill(false,3);
      parameter Boolean isLeft=true;
      parameter SI.RotationalSpringConstant kBase[3]={0,0,0};
      parameter SI.RotationalDampingConstant cBase[3]={0,0,0};
      parameter SI.Angle qNeutral[3]={0,0,0};
      input Real stiffnessScale[3];
      input Real dampingScale[3];
      input Real stiffnessScaleRate[3](each unit="1/s");
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b;
      output SI.Angle q[3]; output SI.AngularVelocity w[3];
      output Real limitUtilization[3];
      output SI.Force reactionForce[3]=frame_a.f;
      output SI.Torque reactionMoment[3]=frame_a.t;
      output SI.Torque generalizedTorque[3];
      output SI.Power generalizedPower;
      output SI.Power stiffnessModulationPower;
      output SI.Force cutForceWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.f);
      output SI.Torque cutMomentWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R,frame_a.t);
      output SI.Power cutPowerIntoA=frame_a.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_a.R,der(frame_a.r_0))
        +frame_a.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_a.R);
      output SI.Power cutPowerIntoB=frame_b.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_b.R,der(frame_b.r_0))
        +frame_b.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_b.R);
      output SI.Power powerToDistalBody=-cutPowerIntoB;
      output SI.Power cutPowerClosure=cutPowerIntoA+cutPowerIntoB+generalizedPower
        "Zero for a massless coincident-center joint with the declared torque sign";
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute flexExt(n={0,-1,0},useAxisFlange=true,
        phi(start=q_start[1],fixed=q_fixed[1]),w(start=w_start[1],fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute addAbd(
        n=if isLeft then {-1,0,0} else {1,0,0},useAxisFlange=true,
        phi(start=q_start[2],fixed=q_fixed[2]),w(start=w_start[2],fixed=w_fixed[2]));
      Modelica.Mechanics.MultiBody.Joints.Revolute intExt(
        n=if isLeft then {0,0,-1} else {0,0,1},useAxisFlange=true,
        phi(start=q_start[3],fixed=q_fixed[3]),w(start=w_start[3],fixed=w_fixed[3]));
      VariableImpedance1D imp[3](kBase=kBase,cBase=cBase,qNeutral=qNeutral);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=3,mobility=mobility);
    equation
      connect(frame_a,flexExt.frame_a); connect(flexExt.frame_b,addAbd.frame_a);
      connect(addAbd.frame_b,intExt.frame_a); connect(intExt.frame_b,frame_b);
      connect(flexExt.axis,imp[1].flange_a); connect(flexExt.support,imp[1].flange_b);
      connect(addAbd.axis,imp[2].flange_a); connect(addAbd.support,imp[2].flange_b);
      connect(intExt.axis,imp[3].flange_a); connect(intExt.support,imp[3].flange_b);
      for i in 1:3 loop
        imp[i].stiffnessScale=stiffnessScale[i]; imp[i].dampingScale=dampingScale[i];
        imp[i].stiffnessScaleRate=stiffnessScaleRate[i];
      end for;
      q={flexExt.phi,addAbd.phi,intExt.phi}; w={flexExt.w,addAbd.w,intExt.w};
      monitor.q=q; limitUtilization=monitor.utilization;
      generalizedTorque={flexExt.tau,addAbd.tau,intExt.tau};
      generalizedPower=sum(generalizedTorque.*w);
      stiffnessModulationPower=sum(imp.stiffnessModulationPowerToMechanical);
    end Hip;

    model LumbarSpine3D
      "3-DOF lumbar joint with variable passive impedance and complete cut-wrench diagnostics"
      import SI = Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile mobility(n=3);
      parameter SI.Angle q_start[3]={0,0,0};
      parameter Boolean q_fixed[3]=fill(false,3);
      parameter SI.AngularVelocity w_start[3]=fill(0,3);
      parameter Boolean w_fixed[3]=fill(false,3);
      parameter SI.RotationalSpringConstant kBase[3]={0,0,0};
      parameter SI.RotationalDampingConstant cBase[3]={0,0,0};
      parameter SI.Angle qNeutral[3]={0,0,0};
      input Real stiffnessScale[3];
      input Real dampingScale[3];
      input Real stiffnessScaleRate[3](each unit="1/s");
      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvis;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_thorax;
      output SI.Angle q[3]; output SI.AngularVelocity w[3];
      output Real limitUtilization[3];
      output SI.Force reactionForce[3]=frame_pelvis.f;
      output SI.Torque reactionMoment[3]=frame_pelvis.t;
      output SI.Torque generalizedTorque[3];
      output SI.Power generalizedPower;
      output SI.Power stiffnessModulationPower;
      output SI.Force cutForceWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_pelvis.R,frame_pelvis.f);
      output SI.Torque cutMomentWorld[3]=Modelica.Mechanics.MultiBody.Frames.resolve1(frame_pelvis.R,frame_pelvis.t);
      output SI.Power cutPowerIntoA=frame_pelvis.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_pelvis.R,der(frame_pelvis.r_0))
        +frame_pelvis.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_pelvis.R);
      output SI.Power cutPowerIntoB=frame_thorax.f*Modelica.Mechanics.MultiBody.Frames.resolve2(frame_thorax.R,der(frame_thorax.r_0))
        +frame_thorax.t*Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_thorax.R);
      output SI.Power powerToDistalBody=-cutPowerIntoB;
      output SI.Power cutPowerClosure=cutPowerIntoA+cutPowerIntoB+generalizedPower
        "Zero for a massless coincident-center joint with the declared torque sign";
    protected
      Modelica.Mechanics.MultiBody.Joints.Revolute flexExt(n={0,1,0},useAxisFlange=true,
        phi(start=q_start[1],fixed=q_fixed[1]),w(start=w_start[1],fixed=w_fixed[1]));
      Modelica.Mechanics.MultiBody.Joints.Revolute lateralBend(n={-1,0,0},useAxisFlange=true,
        phi(start=q_start[2],fixed=q_fixed[2]),w(start=w_start[2],fixed=w_fixed[2]));
      Modelica.Mechanics.MultiBody.Joints.Revolute axialRotation(n={0,0,1},useAxisFlange=true,
        phi(start=q_start[3],fixed=q_fixed[3]),w(start=w_start[3],fixed=w_fixed[3]));
      VariableImpedance1D imp[3](kBase=kBase,cBase=cBase,qNeutral=qNeutral);
      ModelicaHumanBodyPArts.Sensors.JointLimitMonitor monitor(n=3,mobility=mobility);
    equation
      connect(frame_pelvis,flexExt.frame_a); connect(flexExt.frame_b,lateralBend.frame_a);
      connect(lateralBend.frame_b,axialRotation.frame_a); connect(axialRotation.frame_b,frame_thorax);
      connect(flexExt.axis,imp[1].flange_a); connect(flexExt.support,imp[1].flange_b);
      connect(lateralBend.axis,imp[2].flange_a); connect(lateralBend.support,imp[2].flange_b);
      connect(axialRotation.axis,imp[3].flange_a); connect(axialRotation.support,imp[3].flange_b);
      for i in 1:3 loop
        imp[i].stiffnessScale=stiffnessScale[i]; imp[i].dampingScale=dampingScale[i];
        imp[i].stiffnessScaleRate=stiffnessScaleRate[i];
      end for;
      q={flexExt.phi,lateralBend.phi,axialRotation.phi}; w={flexExt.w,lateralBend.w,axialRotation.w};
      monitor.q=q; limitUtilization=monitor.utilization;
      generalizedTorque={flexExt.tau,lateralBend.tau,axialRotation.tau};
      generalizedPower=sum(generalizedTorque.*w);
      stiffnessModulationPower=sum(imp.stiffnessModulationPowerToMechanical);
    end LumbarSpine3D;

    model LowerBodyAxialAssembly
      "Bilateral transmission assembly with rigid pelvic ring, variable-impedance lumbar/hips and diagnostic knee/ankle joints"
      import SI=Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pelvicProps;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D thoraxProps;
      parameter SI.Length lumbosacralToHipVertical;
      parameter SI.Length shoulderWidth;
      parameter SI.Length shoulderHeight=0.75*thoraxProps.length;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarMobility(n=3);
      parameter Boolean fixInitialJointCoordinates=false;
      parameter Boolean fixInitialJointVelocities=false;
      parameter SI.Angle leftHipStart[3]=zeros(3),rightHipStart[3]=zeros(3);
      parameter SI.Angle leftKneeStart=0,rightKneeStart=0;
      parameter SI.Angle leftAnkleStart[2]=zeros(2),rightAnkleStart[2]=zeros(2);
      parameter SI.Angle lumbarStart[3]=zeros(3);
      parameter Boolean lumbarFixed[3]=fill(false,3);
      parameter SI.AngularVelocity lumbarWStart[3]=zeros(3);
      parameter Boolean lumbarWFixed[3]=fill(false,3);
      parameter SI.RotationalSpringConstant hipK[3]={0,0,0};
      parameter SI.RotationalDampingConstant hipC[3]={0,0,0};
      parameter SI.Angle hipNeutral[3]={0,0,0};
      parameter SI.RotationalSpringConstant kneeK=0;
      parameter SI.RotationalDampingConstant kneeC=0;
      parameter SI.RotationalSpringConstant ankleK[2]={0,0};
      parameter SI.RotationalDampingConstant ankleC[2]={0,0};
      parameter SI.RotationalSpringConstant lumbarK[3]={0,0,0};
      parameter SI.RotationalDampingConstant lumbarC[3]={0,0,0};
      parameter Boolean useVariableImpedance=false
        "If true, hip/lumbar scale commands are supplied through control connectors";
      Modelica.Blocks.Interfaces.RealInput leftHipControl[9] if useVariableImpedance;
      Modelica.Blocks.Interfaces.RealInput rightHipControl[9] if useVariableImpedance;
      Modelica.Blocks.Interfaces.RealInput lumbarControl[9] if useVariableImpedance;
      parameter SI.Length footCOMAboveSole=0;
      parameter String footCOMOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE";
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisReference;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftPlantarFrames[6],rightPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftFootReference,rightFootReference;

      output SI.Mass representedMass;
      output SI.Angle leftQ[6],rightQ[6],lumbarQ[3];
      output SI.AngularVelocity leftW[6],rightW[6],lumbarW[3];
      output SI.Force leftHipReactionForce[3],rightHipReactionForce[3],leftKneeReactionForce[3],rightKneeReactionForce[3],leftAnkleReactionForce[3],rightAnkleReactionForce[3],lumbosacralForce[3];
      output SI.Torque leftHipReactionMoment[3],rightHipReactionMoment[3],leftKneeReactionMoment[3],rightKneeReactionMoment[3],leftAnkleReactionMoment[3],rightAnkleReactionMoment[3],lumbosacralMoment[3];
      output SI.Torque leftHipTorque[3],rightHipTorque[3],leftAnkleTorque[2],rightAnkleTorque[2],lumbarTorque[3];
      output SI.Torque leftKneeTorque,rightKneeTorque;
      output SI.Power leftHipPower,rightHipPower,leftKneePower,rightKneePower,leftAnklePower,rightAnklePower,lumbarPower;
      output SI.Power totalStiffnessModulationPower;

      output SI.Force cutForcesWorld[7,3] "Left ankle,knee,hip; right ankle,knee,hip; lumbar";
      output SI.Torque cutMomentsWorld[7,3];
      output SI.Power powerIntoProximalCut[7],powerToDistalBody[7],cutPowerClosure[7];
      output SI.Position segmentCOMWorld[8,3] "Pelvis,trunk,left thigh/shank/foot,right thigh/shank/foot";
      output SI.Position representedCOMWorld[3];
      output SI.Velocity representedCOMVelocity[3];
      output SI.Acceleration representedCOMAcceleration[3];
      output SI.Angle pelvisYawWorld,thoraxYawWorld;
      output Boolean pelvisYawValid,thoraxYawValid;
      output SI.Position leftToeWorld[3]=leftFoot.frame_toe.r_0;
      output SI.Position rightToeWorld[3]=rightFoot.frame_toe.r_0;
    protected
      Real pelvisForwardWorld[3],thoraxForwardWorld[3];
      parameter SI.Mass segmentMasses[8]={pelvicProps.mass,thoraxProps.mass,
        thighProps.mass,shankProps.mass,footProps.mass,thighProps.mass,shankProps.mass,footProps.mass};
      Real leftHipKScale[3],leftHipCScale[3],leftHipKRate[3];
      Real rightHipKScale[3],rightHipCScale[3],rightHipKRate[3];
      Real lumbarKScale[3],lumbarCScale[3],lumbarKRate[3];
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      ModelicaHumanBodyPArts.AxialBody.PelvicRing pelvis(props=pelvicProps,hipCenterDistance=profile.hipCenterDistance,lumbosacralToHipVertical=lumbosacralToHipVertical,animation=animation);
      LumbarSpine3D lumbar(mobility=lumbarMobility,q_start=lumbarStart,q_fixed=lumbarFixed,w_start=lumbarWStart,w_fixed=lumbarWFixed,kBase=lumbarK,cBase=lumbarC);
      ModelicaHumanBodyPArts.AxialBody.Thorax thorax(props=thoraxProps,shoulderWidth=shoulderWidth,shoulderHeight=shoulderHeight,animation=animation);
      Hip leftHip(mobility=hipMobility,isLeft=true,q_start=leftHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=hipK,cBase=hipC,qNeutral=hipNeutral);
      Hip rightHip(mobility=hipMobility,isLeft=false,q_start=rightHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=hipK,cBase=hipC,qNeutral=hipNeutral);
      ModelicaHumanBodyPArts.Segments.Thigh leftThigh(props=thighProps,animation=animation),rightThigh(props=thighProps,animation=animation);
      Knee leftKnee(mobility=kneeMobility,phi_start=leftKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=kneeK,cBase=kneeC);
      Knee rightKnee(mobility=kneeMobility,phi_start=rightKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=kneeK,cBase=kneeC);
      ModelicaHumanBodyPArts.Segments.Shank leftShank(props=shankProps,animation=animation),rightShank(props=shankProps,animation=animation);
      AnkleComplex leftAnkle(mobility=ankleMobility,isLeft=true,q_start=leftAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=ankleK,cBase=ankleC);
      AnkleComplex rightAnkle(mobility=ankleMobility,isLeft=false,q_start=rightAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=ankleK,cBase=ankleC);
      ModelicaHumanBodyPArts.Segments.Foot leftFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=true);
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=false);
    equation
      cutForcesWorld[1,:]=leftAnkle.cutForceWorld;
      cutMomentsWorld[1,:]=leftAnkle.cutMomentWorld;
      powerIntoProximalCut[1]=leftAnkle.cutPowerIntoA;
      powerToDistalBody[1]=leftAnkle.powerToDistalBody;
      cutPowerClosure[1]=leftAnkle.cutPowerClosure;
      cutForcesWorld[2,:]=leftKnee.cutForceWorld;
      cutMomentsWorld[2,:]=leftKnee.cutMomentWorld;
      powerIntoProximalCut[2]=leftKnee.cutPowerIntoA;
      powerToDistalBody[2]=leftKnee.powerToDistalBody;
      cutPowerClosure[2]=leftKnee.cutPowerClosure;
      cutForcesWorld[3,:]=leftHip.cutForceWorld;
      cutMomentsWorld[3,:]=leftHip.cutMomentWorld;
      powerIntoProximalCut[3]=leftHip.cutPowerIntoA;
      powerToDistalBody[3]=leftHip.powerToDistalBody;
      cutPowerClosure[3]=leftHip.cutPowerClosure;
      cutForcesWorld[4,:]=rightAnkle.cutForceWorld;
      cutMomentsWorld[4,:]=rightAnkle.cutMomentWorld;
      powerIntoProximalCut[4]=rightAnkle.cutPowerIntoA;
      powerToDistalBody[4]=rightAnkle.powerToDistalBody;
      cutPowerClosure[4]=rightAnkle.cutPowerClosure;
      cutForcesWorld[5,:]=rightKnee.cutForceWorld;
      cutMomentsWorld[5,:]=rightKnee.cutMomentWorld;
      powerIntoProximalCut[5]=rightKnee.cutPowerIntoA;
      powerToDistalBody[5]=rightKnee.powerToDistalBody;
      cutPowerClosure[5]=rightKnee.cutPowerClosure;
      cutForcesWorld[6,:]=rightHip.cutForceWorld;
      cutMomentsWorld[6,:]=rightHip.cutMomentWorld;
      powerIntoProximalCut[6]=rightHip.cutPowerIntoA;
      powerToDistalBody[6]=rightHip.powerToDistalBody;
      cutPowerClosure[6]=rightHip.cutPowerClosure;
      cutForcesWorld[7,:]=lumbar.cutForceWorld;
      cutMomentsWorld[7,:]=lumbar.cutMomentWorld;
      powerIntoProximalCut[7]=lumbar.cutPowerIntoA;
      powerToDistalBody[7]=lumbar.powerToDistalBody;
      cutPowerClosure[7]=lumbar.cutPowerClosure;
      segmentCOMWorld[1,:]=pelvis.frame_lumbosacral.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(pelvis.frame_lumbosacral.R,pelvicProps.rCM);
      segmentCOMWorld[2,:]=thorax.frame_lumbar.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(thorax.frame_lumbar.R,thoraxProps.rCM);
      segmentCOMWorld[3,:]=leftThigh.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(leftThigh.frame_proximal.R,{0,0,-thighProps.comDistance});
      segmentCOMWorld[4,:]=leftShank.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(leftShank.frame_proximal.R,{0,0,-shankProps.comDistance});
      segmentCOMWorld[5,:]=leftFoot.frame_ankle.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(leftFoot.frame_ankle.R,leftFoot.comPositionLocal);
      segmentCOMWorld[6,:]=rightThigh.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(rightThigh.frame_proximal.R,{0,0,-thighProps.comDistance});
      segmentCOMWorld[7,:]=rightShank.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(rightShank.frame_proximal.R,{0,0,-shankProps.comDistance});
      segmentCOMWorld[8,:]=rightFoot.frame_ankle.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(rightFoot.frame_ankle.R,rightFoot.comPositionLocal);
      for j in 1:3 loop
        representedCOMWorld[j]=sum({segmentMasses[i]*segmentCOMWorld[i,j] for i in 1:8})/representedMass;
      end for;
      representedCOMVelocity=der(representedCOMWorld);
      representedCOMAcceleration=der(representedCOMVelocity);
      pelvisForwardWorld=Modelica.Mechanics.MultiBody.Frames.resolve1(pelvis.frame_lumbosacral.R,{1,0,0});
      thoraxForwardWorld=Modelica.Mechanics.MultiBody.Frames.resolve1(thorax.frame_lumbar.R,{1,0,0});
      pelvisYawValid=pelvisForwardWorld[1]^2+pelvisForwardWorld[2]^2>1e-12;
      thoraxYawValid=thoraxForwardWorld[1]^2+thoraxForwardWorld[2]^2>1e-12;
      pelvisYawWorld=atan2(pelvisForwardWorld[2],pelvisForwardWorld[1]);
      thoraxYawWorld=atan2(thoraxForwardWorld[2],thoraxForwardWorld[1]);
      connect(frame_pelvisReference,pelvis.frame_lumbosacral); connect(pelvis.frame_lumbosacral,lumbar.frame_pelvis); connect(lumbar.frame_thorax,thorax.frame_lumbar); connect(thorax.frame_cervical,frame_cervical);
      connect(pelvis.frame_leftHip,leftHip.frame_a); connect(leftHip.frame_b,leftThigh.frame_proximal); connect(leftThigh.frame_distal,leftKnee.frame_a); connect(leftKnee.frame_b,leftShank.frame_proximal); connect(leftShank.frame_distal,leftAnkle.frame_a); connect(leftAnkle.frame_b,leftFoot.frame_ankle); connect(leftFoot.frame_ankle,leftFootReference);
      connect(pelvis.frame_rightHip,rightHip.frame_a); connect(rightHip.frame_b,rightThigh.frame_proximal); connect(rightThigh.frame_distal,rightKnee.frame_a); connect(rightKnee.frame_b,rightShank.frame_proximal); connect(rightShank.frame_distal,rightAnkle.frame_a); connect(rightAnkle.frame_b,rightFoot.frame_ankle); connect(rightFoot.frame_ankle,rightFootReference);
      for i in 1:6 loop connect(leftFoot.frame_plantar[i],leftPlantarFrames[i]); connect(rightFoot.frame_plantar[i],rightPlantarFrames[i]); end for;
      if useVariableImpedance then
        leftHipKScale=leftHipControl[1:3]; leftHipCScale=leftHipControl[4:6]; leftHipKRate=leftHipControl[7:9];
        rightHipKScale=rightHipControl[1:3]; rightHipCScale=rightHipControl[4:6]; rightHipKRate=rightHipControl[7:9];
        lumbarKScale=lumbarControl[1:3]; lumbarCScale=lumbarControl[4:6]; lumbarKRate=lumbarControl[7:9];
      else
        leftHipKScale=fill(1,3); leftHipCScale=fill(1,3); leftHipKRate=zeros(3);
        rightHipKScale=fill(1,3); rightHipCScale=fill(1,3); rightHipKRate=zeros(3);
        lumbarKScale=fill(1,3); lumbarCScale=fill(1,3); lumbarKRate=zeros(3);
      end if;
      leftHip.stiffnessScale=leftHipKScale; leftHip.dampingScale=leftHipCScale; leftHip.stiffnessScaleRate=leftHipKRate;
      rightHip.stiffnessScale=rightHipKScale; rightHip.dampingScale=rightHipCScale; rightHip.stiffnessScaleRate=rightHipKRate;
      leftKnee.stiffnessScale=1; leftKnee.dampingScale=1; leftKnee.stiffnessScaleRate=0;
      rightKnee.stiffnessScale=1; rightKnee.dampingScale=1; rightKnee.stiffnessScaleRate=0;
      leftAnkle.stiffnessScale=fill(1,2); leftAnkle.dampingScale=fill(1,2); leftAnkle.stiffnessScaleRate=zeros(2);
      rightAnkle.stiffnessScale=fill(1,2); rightAnkle.dampingScale=fill(1,2); rightAnkle.stiffnessScaleRate=zeros(2);
      lumbar.stiffnessScale=lumbarKScale; lumbar.dampingScale=lumbarCScale; lumbar.stiffnessScaleRate=lumbarKRate;
      leftQ=cat(1,leftHip.q,{leftKnee.q},leftAnkle.q); rightQ=cat(1,rightHip.q,{rightKnee.q},rightAnkle.q); lumbarQ=lumbar.q;
      leftW=cat(1,leftHip.w,{leftKnee.w},leftAnkle.w); rightW=cat(1,rightHip.w,{rightKnee.w},rightAnkle.w); lumbarW=lumbar.w;
      representedMass=pelvicProps.mass+thoraxProps.mass+2*(thighProps.mass+shankProps.mass+footProps.mass);
      leftHipReactionForce=leftHip.reactionForce; rightHipReactionForce=rightHip.reactionForce; leftKneeReactionForce=leftKnee.reactionForce; rightKneeReactionForce=rightKnee.reactionForce; leftAnkleReactionForce=leftAnkle.reactionForce; rightAnkleReactionForce=rightAnkle.reactionForce; lumbosacralForce=lumbar.reactionForce;
      leftHipReactionMoment=leftHip.reactionMoment; rightHipReactionMoment=rightHip.reactionMoment; leftKneeReactionMoment=leftKnee.reactionMoment; rightKneeReactionMoment=rightKnee.reactionMoment; leftAnkleReactionMoment=leftAnkle.reactionMoment; rightAnkleReactionMoment=rightAnkle.reactionMoment; lumbosacralMoment=lumbar.reactionMoment;
      leftHipTorque=leftHip.generalizedTorque; rightHipTorque=rightHip.generalizedTorque; leftKneeTorque=leftKnee.generalizedTorque; rightKneeTorque=rightKnee.generalizedTorque; leftAnkleTorque=leftAnkle.generalizedTorque; rightAnkleTorque=rightAnkle.generalizedTorque; lumbarTorque=lumbar.generalizedTorque;
      leftHipPower=leftHip.generalizedPower; rightHipPower=rightHip.generalizedPower; leftKneePower=leftKnee.generalizedPower; rightKneePower=rightKnee.generalizedPower; leftAnklePower=leftAnkle.generalizedPower; rightAnklePower=rightAnkle.generalizedPower; lumbarPower=lumbar.generalizedPower;
      totalStiffnessModulationPower=leftHip.stiffnessModulationPower+rightHip.stiffnessModulationPower+leftKnee.stiffnessModulationPower+rightKnee.stiffnessModulationPower+leftAnkle.stiffnessModulationPower+rightAnkle.stiffnessModulationPower+lumbar.stiffnessModulationPower;
      annotation(Documentation(info="<html><p>This v0.9.1 assembly exposes cut reaction wrenches at ankle, knee, hip and lumbosacral interfaces and generalized torque/power for the explicit impedance coordinates. It still does not identify individual muscles or cartilage contact stress.</p></html>"));
    end LowerBodyAxialAssembly;

    block QuinticYawMission
      "Analytic support-yaw mission profile with exact first and second derivatives available to Modelica"
      parameter Modelica.Units.SI.Angle amplitude=20*Modelica.Constants.pi/180;
      parameter Modelica.Units.SI.Time duration=0.25;
      output Modelica.Units.SI.Angle phi;
    protected
      Real u;
    equation
      u=min(1,max(0,time/duration));
      phi=amplitude*(10*u^3-15*u^4+6*u^5);
    end QuinticYawMission;

    model LiteratureRotationalTransmissionCase
      "Literature-informed rotational sensitivity case with transmission metrics; not a validated human prediction"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter Real lumbarKax(unit="N.m/rad")=19.480565
        "Watt 2022 ROM-quarter Q2 slope; constant sensitivity value, not population quartile";
      parameter Real lumbarCax(unit="N.m.s/rad")=0.8 "Explicit damping assumption";
      parameter Real hipKax(unit="N.m/rad")=4 "S50-R1 sensitivity parameter; not a human constant";
      parameter Real hipCax(unit="N.m.s/rad")=4 "S50-R1 sensitivity parameter; not a human constant";
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.224,hipCenterDistance=0.20,geometrySourceId="MIXED_PUBLIC_LITERATURE_NOMINAL_MALE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=10.65,length=0.224,rCM={-0.075264,0.000672,-0.033376},I_CM={{0.09426364,0.00133594,-0.00534374},{0.00133594,0.08549990,0.00048094},{-0.00534374,0.00048094,0.10345488}},R_principal=identity(3),segmentFrameId="DUMAS2007_MALE_PELVIS_CONVERTED_X_ANT_Y_LEFT_Z_SUP");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=24.975,length=0.485,rCM={0.00227498,0.00125910,0.28193904},I_CM={{0.545069637,-0.000030015,-0.019639192},{-0.000030015,0.420862030,-0.002521310},{-0.019639192,-0.002521310,0.299943509}},R_principal=identity(3),segmentFrameId="DUMAS2015_MALE_ABDOMEN_PLUS_THORAX_COMPOSITE_AT_LJC");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SENSITIVITY_GATE_NOT_CLINICAL_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-1},qMax={2.8},sourceId="SENSITIVITY_GATE_NOT_CLINICAL_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-1,-1},qMax={1,1},sourceId="SENSITIVITY_GATE_NOT_CLINICAL_ROM");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin={-1,-1,-24*Modelica.Constants.pi/180},qMax={1,1,24*Modelica.Constants.pi/180},sourceId="ASSUMED_PLUS_MINUS_24_DEG_NOT_SHIN_TOTAL_RANGE");
      Modelica.Mechanics.MultiBody.Parts.Fixed ground(animation=false);
      Modelica.Mechanics.MultiBody.Joints.Revolute standingYaw(n={0,0,1},useAxisFlange=true,phi(start=0,fixed=true),w(start=0,fixed=true));
      Modelica.Mechanics.Rotational.Sources.Torque torqueSource(useSupport=true);
      LowerBodyAxialAssembly body(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.224,shoulderWidth=0.40,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,hipK={0,0,hipKax},hipC={0,0,hipCax},lumbarK={0,0,lumbarKax},lumbarC={0,0,lumbarCax},fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},lumbarWFixed={true,true,true},animation=false);
      InterfaceLoadMetrics hipMetrics(n=3,declaredBodyMass=profile.mass,representedMass=body.representedMass);
      InterfaceLoadMetrics kneeMetrics(n=1,declaredBodyMass=profile.mass,representedMass=body.representedMass);
      InterfaceLoadMetrics ankleMetrics(n=2,declaredBodyMass=profile.mass,representedMass=body.representedMass);
      InterfaceLoadMetrics lumbarMetrics(n=3,declaredBodyMass=profile.mass,representedMass=body.representedMass);
      output SI.Torque appliedGroundTorque;
      output SI.Angle standingFootYaw=standingYaw.phi,standingHipAxial=body.leftQ[3],freeHipAxial=body.rightQ[3],pelvisYawProxy=standingFootYaw+standingHipAxial,lumbarAxial=body.lumbarQ[3],thoraxYawProxy=pelvisYawProxy+lumbarAxial;
      output Real lumbarUtilization=abs(lumbarAxial)/(24*Modelica.Constants.pi/180);
      output Real hipForceBW=hipMetrics.forcePerDeclaredBW,kneeForceBW=kneeMetrics.forcePerDeclaredBW,
        ankleForceBW=ankleMetrics.forcePerDeclaredBW,lumbarForceBW=lumbarMetrics.forcePerDeclaredBW;
      output SI.Torque hipMoment=hipMetrics.momentNorm,kneeMoment=kneeMetrics.momentNorm,
        ankleMoment=ankleMetrics.momentNorm,lumbarMoment=lumbarMetrics.momentNorm;
      output Real hipForceRate=hipMetrics.forceLoadingRate,kneeForceRate=kneeMetrics.forceLoadingRate,
        ankleForceRate=ankleMetrics.forceLoadingRate,lumbarForceRate=lumbarMetrics.forceLoadingRate;
      output Real hipMomentRate=hipMetrics.momentLoadingRate,kneeMomentRate=kneeMetrics.momentLoadingRate,
        ankleMomentRate=ankleMetrics.momentLoadingRate,lumbarMomentRate=lumbarMetrics.momentLoadingRate;
      output Real hipForceImpulse=hipMetrics.forceImpulse,kneeForceImpulse=kneeMetrics.forceImpulse,
        ankleForceImpulse=ankleMetrics.forceImpulse,lumbarForceImpulse=lumbarMetrics.forceImpulse;
      output Real hipMomentImpulse=hipMetrics.momentImpulse,kneeMomentImpulse=kneeMetrics.momentImpulse,
        ankleMomentImpulse=ankleMetrics.momentImpulse,lumbarMomentImpulse=lumbarMetrics.momentImpulse;
      output SI.Power hipPower=hipMetrics.generalizedPower,kneePower=kneeMetrics.generalizedPower,
        anklePower=ankleMetrics.generalizedPower,lumbarPower=lumbarMetrics.generalizedPower;
      output SI.Energy hipPositiveWork=hipMetrics.positiveWork,kneePositiveWork=kneeMetrics.positiveWork,
        anklePositiveWork=ankleMetrics.positiveWork,lumbarPositiveWork=lumbarMetrics.positiveWork;
      output SI.Energy hipNegativeWork=hipMetrics.negativeWork,kneeNegativeWork=kneeMetrics.negativeWork,
        ankleNegativeWork=ankleMetrics.negativeWork,lumbarNegativeWork=lumbarMetrics.negativeWork;
      output Real hipHighLoadLowMotion=hipMetrics.highLoadLowMotionRatio,
        kneeHighLoadLowMotion=kneeMetrics.highLoadLowMotionRatio,
        ankleHighLoadLowMotion=ankleMetrics.highLoadLowMotionRatio,
        lumbarHighLoadLowMotion=lumbarMetrics.highLoadLowMotionRatio;
    equation
      connect(ground.frame_b,standingYaw.frame_a); connect(standingYaw.frame_b,body.leftPlantarFrames[1]); connect(torqueSource.flange,standingYaw.axis); connect(torqueSource.support,standingYaw.support);
      appliedGroundTorque=if time<0.05 then 0 else if time<0.25 then 5 else 0; torqueSource.tau=appliedGroundTorque;
      hipMetrics.force=body.leftHipReactionForce; hipMetrics.moment=body.leftHipReactionMoment; hipMetrics.generalizedTorque=body.leftHipTorque; hipMetrics.generalizedSpeed=body.leftW[1:3];
      kneeMetrics.force=body.leftKneeReactionForce; kneeMetrics.moment=body.leftKneeReactionMoment; kneeMetrics.generalizedTorque={body.leftKneeTorque}; kneeMetrics.generalizedSpeed={body.leftW[4]};
      ankleMetrics.force=body.leftAnkleReactionForce; ankleMetrics.moment=body.leftAnkleReactionMoment; ankleMetrics.generalizedTorque=body.leftAnkleTorque; ankleMetrics.generalizedSpeed=body.leftW[5:6];
      lumbarMetrics.force=body.lumbosacralForce; lumbarMetrics.moment=body.lumbosacralMoment; lumbarMetrics.generalizedTorque=body.lumbarTorque; lumbarMetrics.generalizedSpeed=body.lumbarW;
      annotation(experiment(StartTime=0,StopTime=0.5,Tolerance=1e-8,Interval=0.0005),Documentation(info="<html><p>Pelvis/thorax mass properties are literature-informed project inputs. Watt et al. 2022 motivates range-quarter slope sensitivity; lumbar damping and hip impedance remain explicit sensitivity assumptions. Shin 2013 reports a 23.9 degree summed left-to-right excursion, not a plus/minus 24 degree bound. The retained plus/minus 24 degree gate is an explicit unvalidated numerical assumption. Watt quartiles refer to quarters of motion range, not four population quartiles. This is not human validation of Lynkorr.</p></html>"));
    end LiteratureRotationalTransmissionCase;

    model LoadMetricsAnalyticTest
      "Analytic verification of wrench magnitude, loading rates, impulses and work"
      InterfaceLoadMetrics m(n=1,declaredBodyMass=1,representedMass=1,g=10);
      output Integer checksPassed(start=0,fixed=true);
    equation
      m.force={3*time,4*time,0}; m.moment={0,0,2*time}; m.generalizedTorque={2*time}; m.generalizedSpeed={1};
    algorithm
      when time>=0.999 then
        assert(abs(m.forceNorm-5*time)<1e-7,"Force norm mismatch");
        assert(abs(m.forceLoadingRate-5)<1e-6,"Force loading-rate mismatch");
        assert(abs(m.momentLoadingRate-2)<1e-6,"Moment loading-rate mismatch");
        assert(abs(m.forceImpulse-2.5)<0.01,"Force impulse mismatch");
        assert(abs(m.momentImpulse-1)<0.01,"Moment impulse mismatch");
        assert(abs(m.positiveWork-1)<0.01,"Positive work mismatch");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1,Tolerance=1e-9,Interval=0.001));
    end LoadMetricsAnalyticTest;

    model KinematicSmoothnessAnalyticTest
      "Analytic verification of acceleration-to-jerk diagnostics"
      KinematicSmoothnessMetrics m;
      output Integer checksPassed(start=0,fixed=true);
    equation
      m.acceleration={time^2,0,0};
    algorithm
      when time>=0.999 then
        assert(abs(m.jerk[1]-2*time)<1e-6,"Jerk mismatch");
        assert(abs(m.jerkExposure-1)<0.01,"Jerk exposure mismatch");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1,Tolerance=1e-9,Interval=0.001));
    end KinematicSmoothnessAnalyticTest;

    model VariableImpedanceEnergyBalanceTest
      "Verification that time-varying stiffness accounts explicitly for modulation energy"
      Modelica.Mechanics.Rotational.Components.Fixed fixed;
      Modelica.Mechanics.Rotational.Components.Inertia inertia(J=0.2,phi(start=0.2,fixed=true),w(start=0,fixed=true));
      VariableImpedance1D imp(kBase=20,cBase=0.5,qNeutral=0);
      SmoothImpedanceSchedule schedule(initialScale=1,preparationScale=1.1,releaseScale=0.5,preparationEnd=0.1,releaseEnd=0.6);
      output Modelica.Units.SI.Energy dissipatedEnergy(start=0,fixed=true);
      output Modelica.Units.SI.Energy modulationEnergy(start=0,fixed=true);
      output Modelica.Units.SI.Energy mechanicalEnergy=0.5*inertia.J*inertia.w^2+imp.elasticEnergy;
      output Modelica.Units.SI.Energy integratedEnergyResidual=mechanicalEnergy+dissipatedEnergy-modulationEnergy-0.4;
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(inertia.flange_a,imp.flange_a); connect(fixed.flange,imp.flange_b);
      imp.stiffnessScale=schedule.scale; imp.dampingScale=schedule.scale; imp.stiffnessScaleRate=schedule.scaleRate;
      der(dissipatedEnergy)=imp.dampingDissipationPower;
      der(modulationEnergy)=imp.modulationPowerIntoStorage;
    algorithm
      when time>=0.9 then
        assert(abs(integratedEnergyResidual)<1e-6,"Integrated inertial/elastic/modulation energy failed");
        assert(abs(imp.energyBalanceResidual)<1e-8,"Variable-impedance energy balance failed");
        assert(imp.dampingDissipationPower>=-1e-10,"Damping dissipation became negative");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=1,Tolerance=1e-9,Interval=0.001));
    end VariableImpedanceEnergyBalanceTest;

    model ImpedanceScheduleNoPropulsionTest
      "Changing impedance at zero displacement/velocity must not create motion or power"
      Modelica.Mechanics.Rotational.Components.Fixed fixed;
      Modelica.Mechanics.Rotational.Components.Inertia inertia(J=0.2,phi(start=0,fixed=true),w(start=0,fixed=true));
      VariableImpedance1D imp(kBase=20,cBase=1,qNeutral=0);
      SmoothImpedanceSchedule schedule;
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(inertia.flange_a,imp.flange_a); connect(fixed.flange,imp.flange_b);
      imp.stiffnessScale=schedule.scale; imp.dampingScale=schedule.scale; imp.stiffnessScaleRate=schedule.scaleRate;
    algorithm
      when time>=0.49 then
        assert(abs(inertia.phi)<1e-12 and abs(inertia.w)<1e-12,"Impedance schedule generated motion from the zero state");
        assert(abs(imp.mechanicalPowerIntoElement)<1e-12 and abs(imp.stiffnessModulationPowerToMechanical)<1e-12,"Impedance schedule generated power from zero deformation");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.5,Tolerance=1e-9,Interval=0.001));
    end ImpedanceScheduleNoPropulsionTest;

    model MatchedImpedanceTaskTest
      "Two identical bodies follow the same support-yaw mission; only internal impedance schedule differs"
      import SI=Modelica.Units.SI;
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.224,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_MATCHED_IMPEDANCE_TASK");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=10.65,length=0.224,rCM={-0.075264,0.000672,-0.033376},I_CM={{0.09426364,0.00133594,-0.00534374},{0.00133594,0.08549990,0.00048094},{-0.00534374,0.00048094,0.10345488}},R_principal=identity(3),segmentFrameId="LITERATURE_INFORMED_PROJECT_INPUT");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=24.975,length=0.485,rCM={0.00227498,0.00125910,0.28193904},I_CM={{0.545069637,-0.000030015,-0.019639192},{-0.000030015,0.420862030,-0.002521310},{-0.019639192,-0.002521310,0.299943509}},R_principal=identity(3),segmentFrameId="LITERATURE_INFORMED_PROJECT_INPUT");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-1,-1,-1},qMax={1,1,1},sourceId="SENSITIVITY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-1},qMax={2.8},sourceId="SENSITIVITY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-1,-1},qMax={1,1},sourceId="SENSITIVITY");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin={-1,-1,-24*Modelica.Constants.pi/180},qMax={1,1,24*Modelica.Constants.pi/180},sourceId="ASSUMED_PLUS_MINUS_24_DEG_NOT_MEASURED");
      Modelica.Mechanics.MultiBody.Parts.Fixed groundHold(animation=false),groundRelease(animation=false);
      Modelica.Mechanics.MultiBody.Joints.Revolute yawHold(n={0,0,1},useAxisFlange=true),yawRelease(n={0,0,1},useAxisFlange=true);
      Modelica.Mechanics.Rotational.Sources.Position posHold(exact=true,useSupport=true),posRelease(exact=true,useSupport=true);
      QuinticYawMission mission;
      SmoothImpedanceSchedule releaseSchedule(initialScale=1,preparationScale=1.2,releaseScale=0.45,preparationEnd=0.05,releaseEnd=0.25);
      LowerBodyAxialAssembly hold(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.224,shoulderWidth=0.40,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,hipK={0,0,4},hipC={0,0,4},lumbarK={0,0,19.480565},lumbarC={0,0,0.8},fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},lumbarWFixed={true,true,true},animation=false);
      LowerBodyAxialAssembly release(useVariableImpedance=true,profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.224,shoulderWidth=0.40,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,hipK={0,0,4},hipC={0,0,4},lumbarK={0,0,19.480565},lumbarC={0,0,0.8},fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},lumbarWFixed={true,true,true},animation=false);
      InterfaceLoadMetrics holdHip(n=3,declaredBodyMass=75,representedMass=hold.representedMass),releaseHip(n=3,declaredBodyMass=75,representedMass=release.representedMass);
      InterfaceLoadMetrics holdLumbar(n=3,declaredBodyMass=75,representedMass=hold.representedMass),releaseLumbar(n=3,declaredBodyMass=75,representedMass=release.representedMass);
      output SI.Angle supportYawHold=yawHold.phi,supportYawRelease=yawRelease.phi;
      output SI.Angle pelvisYawHold=supportYawHold+hold.leftQ[3],pelvisYawRelease=supportYawRelease+release.leftQ[3];
      output SI.Angle lumbarYawHold=hold.lumbarQ[3],lumbarYawRelease=release.lumbarQ[3];
      output SI.Angle thoraxYawHold=pelvisYawHold+lumbarYawHold,thoraxYawRelease=pelvisYawRelease+lumbarYawRelease;
      output Real hipMomentImpulseHold=holdHip.momentImpulse,hipMomentImpulseRelease=releaseHip.momentImpulse;
      output Real lumbarMomentImpulseHold=holdLumbar.momentImpulse,lumbarMomentImpulseRelease=releaseLumbar.momentImpulse;
      output SI.Energy hipNegativeWorkHold=holdHip.negativeWork,hipNegativeWorkRelease=releaseHip.negativeWork;
      output SI.Energy lumbarNegativeWorkHold=holdLumbar.negativeWork,lumbarNegativeWorkRelease=releaseLumbar.negativeWork;
      output SI.Power releaseModulationPower=release.totalStiffnessModulationPower;
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(groundHold.frame_b,yawHold.frame_a); connect(yawHold.frame_b,hold.leftPlantarFrames[1]); connect(posHold.flange,yawHold.axis); connect(posHold.support,yawHold.support); posHold.phi_ref=mission.phi;
      connect(groundRelease.frame_b,yawRelease.frame_a); connect(yawRelease.frame_b,release.leftPlantarFrames[1]); connect(posRelease.flange,yawRelease.axis); connect(posRelease.support,yawRelease.support); posRelease.phi_ref=mission.phi;
      release.leftHipControl={1,1,releaseSchedule.scale,1,1,releaseSchedule.scale,0,0,releaseSchedule.scaleRate};
      release.rightHipControl={1,1,releaseSchedule.scale,1,1,releaseSchedule.scale,0,0,releaseSchedule.scaleRate};
      release.lumbarControl={1,1,releaseSchedule.scale,1,1,releaseSchedule.scale,0,0,releaseSchedule.scaleRate};
      holdHip.force=hold.leftHipReactionForce; holdHip.moment=hold.leftHipReactionMoment; holdHip.generalizedTorque=hold.leftHipTorque; holdHip.generalizedSpeed=hold.leftW[1:3];
      releaseHip.force=release.leftHipReactionForce; releaseHip.moment=release.leftHipReactionMoment; releaseHip.generalizedTorque=release.leftHipTorque; releaseHip.generalizedSpeed=release.leftW[1:3];
      holdLumbar.force=hold.lumbosacralForce; holdLumbar.moment=hold.lumbosacralMoment; holdLumbar.generalizedTorque=hold.lumbarTorque; holdLumbar.generalizedSpeed=hold.lumbarW;
      releaseLumbar.force=release.lumbosacralForce; releaseLumbar.moment=release.lumbosacralMoment; releaseLumbar.generalizedTorque=release.lumbarTorque; releaseLumbar.generalizedSpeed=release.lumbarW;
    algorithm
      when time>=0.49 then
        assert(abs(supportYawHold-supportYawRelease)<1e-10,"Matched task support trajectories diverged");
        assert(abs(supportYawHold-mission.amplitude)<1e-8,"Matched task did not reach prescribed support yaw");
        assert(abs(lumbarYawHold-lumbarYawRelease)>1e-6 or abs(pelvisYawHold-pelvisYawRelease)>1e-6,"Impedance schedule produced no detectable internal mechanical difference");
        checksPassed:=1;
      end when;
      annotation(experiment(StartTime=0,StopTime=0.5,Tolerance=1e-8,Interval=0.0005),Documentation(info="<html><p>This is a matched external kinematic mission, not a matched whole-body endpoint. Both bodies receive the same standing-support yaw trajectory and duration; only the hip/lumbar impedance schedule differs. No conclusion that one strategy is biologically superior is encoded in the assertions.</p></html>"));
    end MatchedImpedanceTaskTest;

    model TransmissionAssemblyBuild
      "Build-only fixture for the v0.9.1 transmission architecture"
      inner Modelica.Mechanics.MultiBody.World world(gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,pelvisLength=0.18,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_V091_BUILD");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,rCM={0,0,-0.05},I_CM={{0.10,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),segmentFrameId="SYNTHETIC_V091_BUILD");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.50,rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1.0}},R_principal=identity(3),segmentFrameId="SYNTHETIC_V091_BUILD");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,qMin={-1,-1,-1},qMax={2,1,1},sourceId="SYNTHETIC");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,qMin={-0.2},qMax={2.8},sourceId="SYNTHETIC");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,qMin={-1,-1},qMax={1,1},sourceId="SYNTHETIC");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,qMin={-0.5,-0.5,-0.5},qMax={0.5,0.5,0.5},sourceId="SYNTHETIC");
      Modelica.Mechanics.MultiBody.Parts.Fixed anchor(r={0,0,1.1},animation=false);
      LowerBodyAxialAssembly body(profile=profile,pelvicProps=pp,thoraxProps=tp,lumbosacralToHipVertical=0.10,shoulderWidth=0.40,hipMobility=hipROM,kneeMobility=kneeROM,ankleMobility=ankleROM,lumbarMobility=lumbarROM,fixInitialJointCoordinates=true,fixInitialJointVelocities=true,lumbarFixed={true,true,true},animation=false);
    equation
      connect(anchor.frame_b,body.frame_pelvisReference);
      annotation(experiment(StartTime=0,StopTime=0.01,Tolerance=1e-8));
    end TransmissionAssemblyBuild;


    block SpatialWrenchPower
      "Full cut power from a wrench and twist at one common origin and reporting frame"
      input Modelica.Units.SI.Force force[3];
      input Modelica.Units.SI.Torque moment[3];
      input Modelica.Units.SI.Velocity velocity[3];
      input Modelica.Units.SI.AngularVelocity angularVelocity[3];
      output Modelica.Units.SI.Power power=force*velocity+moment*angularVelocity;
    end SpatialWrenchPower;

    model SpatialWrenchPowerAnalyticTest
      "Power is invariant under a consistent common-origin shift; Q*qdot is a different quantity"
      SpatialWrenchPower a,b;
      output Integer checksPassed(start=0,fixed=true);
    equation
      a.force={3,4,0}; a.moment={0,0,2};
      a.velocity={1,0,0}; a.angularVelocity={0,0,7};
      b.force=a.force; b.angularVelocity=a.angularVelocity;
      b.moment=a.moment-cross({1,0,0},a.force);
      b.velocity=a.velocity+cross(a.angularVelocity,{1,0,0});
    algorithm
      when time>=0.009 then
        assert(abs(a.power-17)<1e-12 and abs(b.power-a.power)<1e-12,
          "Spatial power origin-shift identity failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.01,Tolerance=1e-9));
    end SpatialWrenchPowerAnalyticTest;

    model ImpedanceNonzeroNeutralTest
      "A nonzero declared neutral posture remains at rest without external drive"
      Modelica.Mechanics.Rotational.Components.Fixed base;
      Modelica.Mechanics.Rotational.Components.Inertia body(J=0.2,phi(start=0.15,fixed=true),w(start=0,fixed=true));
      VariableImpedance1D imp(kBase=20,cBase=0.5,qNeutral=0.15);
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(body.flange_a,imp.flange_a);connect(base.flange,imp.flange_b);
      imp.stiffnessScale=1;imp.dampingScale=1;imp.stiffnessScaleRate=0;
    algorithm
      when time>=0.49 then
        assert(abs(body.phi-0.15)<1e-10 and abs(body.w)<1e-10 and abs(imp.restoringTorque)<1e-10,
          "Nonzero neutral angle sign or equilibrium failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.5,Tolerance=1e-9));
    end ImpedanceNonzeroNeutralTest;


    model LegacyNeutralEquilibriumTest
      "Legacy hip and lumbar joints hold a nonzero declared neutral posture"
      inner Modelica.Mechanics.MultiBody.World world(
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity,
        enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile rom(
        n=3,qMin=fill(-1,3),qMax=fill(1,3),sourceId="SYNTHETIC_NEUTRAL_SIGN_TEST");
      parameter Modelica.Units.SI.Angle neutral[3]={0.1,0.08,-0.12};
      Modelica.Mechanics.MultiBody.Parts.Fixed anchors[2](each animation=false);
      ModelicaHumanBodyPArts.Joints.Hip hip(mobility=rom,qNeutral=neutral,
        q_start=neutral,q_fixed=fill(true,3),w_fixed=fill(true,3),
        kPassive=fill(20,3),cPassive=fill(1,3));
      ModelicaHumanBodyPArts.AxialBody.LumbarSpine3D lumbar(mobility=rom,qNeutral=neutral,
        q_start=neutral,q_fixed=fill(true,3),w_fixed=fill(true,3),
        kPassive=fill(20,3),cPassive=fill(1,3));
      Modelica.Mechanics.MultiBody.Parts.Body masses[2](each animation=false,
        each m=1,each r_CM={0,0,0},each I_11=0.1,each I_22=0.1,each I_33=0.1);
      output Integer checksPassed(start=0,fixed=true);
    equation
      connect(anchors[1].frame_b,hip.frame_a);connect(hip.frame_b,masses[1].frame_a);
      connect(anchors[2].frame_b,lumbar.frame_pelvis);connect(lumbar.frame_thorax,masses[2].frame_a);
    algorithm
      when time>=0.49 then
        assert(max(abs(hip.q-neutral))<1e-9 and max(abs(lumbar.q-neutral))<1e-9,
          "Legacy nonzero neutral-angle convention failed");
        assert(max(abs(hip.w))<1e-9 and max(abs(lumbar.w))<1e-9,
          "Legacy neutral posture generated motion");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.5,Tolerance=1e-9));
    end LegacyNeutralEquilibriumTest;

  end Transmission;

  package SupportInitiation
    "M2b: gravity-loaded support-side actuation, passive free leg, checked rigid contact"
    extends Modelica.Icons.Package;
    function unitStep5
      input Real u;
      output Real y;
    algorithm
      y:=if u<=0 then 0 else if u>=1 then 1 else 10*u^3-15*u^4+6*u^5;
    end unitStep5;
    block SmoothSupportPulse
      parameter Modelica.Units.SI.Time onset=0.10,rise=0.10,hold=0.15,fall=0.10;
      output Real y;
    equation
      assert(rise>0 and fall>0 and hold>=0,"Invalid pulse times");
      y=unitStep5((time-onset)/rise)-unitStep5((time-onset-rise-hold)/fall);
    end SmoothSupportPulse;
    model HipDrive
      "Standing hip only: explicit internal drive, no free-leg active source"
      extends ModelicaHumanBodyPArts.Transmission.Hip;
      input Modelica.Units.SI.Torque drive[3];
    protected
      Modelica.Mechanics.Rotational.Sources.Torque motor[3](each useSupport=true);
    equation
      connect(motor[1].flange,flexExt.axis);connect(motor[1].support,flexExt.support);
      connect(motor[2].flange,addAbd.axis);connect(motor[2].support,addAbd.support);
      connect(motor[3].flange,intExt.axis);connect(motor[3].support,intExt.support);
      for j in 1:3 loop motor[j].tau=drive[j];end for;
    end HipDrive;
    model AnkleDrive
      "Standing ankle only: shear-inducing internal pitch effort"
      extends ModelicaHumanBodyPArts.Transmission.AnkleComplex;
      input Modelica.Units.SI.Torque drive[2];
    protected
      Modelica.Mechanics.Rotational.Sources.Torque motor[2](each useSupport=true);
    equation
      connect(motor[1].flange,dorsiPlantar.axis);connect(motor[1].support,dorsiPlantar.support);
      connect(motor[2].flange,inversionEversion.axis);connect(motor[2].support,inversionEversion.support);
      for j in 1:2 loop motor[j].tau=drive[j];end for;
    end AnkleDrive;

    model LoadedSupportBody
      "Bilateral transmission assembly with rigid pelvic ring, variable-impedance lumbar/hips and diagnostic knee/ankle joints"
      import SI=Modelica.Units.SI;
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pelvicProps;
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D thoraxProps;
      parameter SI.Length lumbosacralToHipVertical;
      parameter SI.Length shoulderWidth;
      parameter SI.Length shoulderHeight=0.75*thoraxProps.length;
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipMobility(n=3);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeMobility(n=1);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleMobility(n=2);
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarMobility(n=3);
      parameter Boolean fixInitialJointCoordinates=false;
      parameter Boolean fixInitialJointVelocities=false;
      parameter SI.Angle leftHipStart[3]=zeros(3),rightHipStart[3]=zeros(3);
      parameter SI.Angle leftKneeStart=0,rightKneeStart=0;
      parameter SI.Angle leftAnkleStart[2]=zeros(2),rightAnkleStart[2]=zeros(2);
      parameter SI.Angle lumbarStart[3]=zeros(3);
      parameter Boolean lumbarFixed[3]=fill(false,3);
      parameter SI.AngularVelocity lumbarWStart[3]=zeros(3);
      parameter Boolean lumbarWFixed[3]=fill(false,3);
      parameter SI.RotationalSpringConstant hipK[3]={0,0,0};
      parameter SI.RotationalDampingConstant hipC[3]={0,0,0};
      parameter SI.Angle hipNeutral[3]={0,0,0};
      parameter SI.RotationalSpringConstant kneeK=0;
      parameter SI.RotationalDampingConstant kneeC=0;
      parameter SI.RotationalSpringConstant ankleK[2]={0,0};
      parameter SI.RotationalDampingConstant ankleC[2]={0,0};
      parameter SI.RotationalSpringConstant lumbarK[3]={0,0,0};
      parameter SI.RotationalDampingConstant lumbarC[3]={0,0,0};
      parameter Boolean useVariableImpedance=false
        "If true, hip/lumbar scale commands are supplied through control connectors";
      Modelica.Blocks.Interfaces.RealInput leftHipControl[9] if useVariableImpedance;
      Modelica.Blocks.Interfaces.RealInput rightHipControl[9] if useVariableImpedance;
      Modelica.Blocks.Interfaces.RealInput lumbarControl[9] if useVariableImpedance;
      parameter SI.Length footCOMAboveSole=0;
      parameter String footCOMOffsetSourceId="ASSUMPTION_LEGACY_SOLE_PLANE";
      parameter Boolean animation=true;

      Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_pelvisReference;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_cervical;
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftPlantarFrames[6],rightPlantarFrames[6];
      Modelica.Mechanics.MultiBody.Interfaces.Frame_b leftFootReference,rightFootReference;

      output SI.Mass representedMass;
      output SI.Angle leftQ[6],rightQ[6],lumbarQ[3];
      output SI.AngularVelocity leftW[6],rightW[6],lumbarW[3];
      output SI.Force leftHipReactionForce[3],rightHipReactionForce[3],leftKneeReactionForce[3],rightKneeReactionForce[3],leftAnkleReactionForce[3],rightAnkleReactionForce[3],lumbosacralForce[3];
      output SI.Torque leftHipReactionMoment[3],rightHipReactionMoment[3],leftKneeReactionMoment[3],rightKneeReactionMoment[3],leftAnkleReactionMoment[3],rightAnkleReactionMoment[3],lumbosacralMoment[3];
      output SI.Torque leftHipTorque[3],rightHipTorque[3],leftAnkleTorque[2],rightAnkleTorque[2],lumbarTorque[3];
      output SI.Torque leftKneeTorque,rightKneeTorque;
      output SI.Power leftHipPower,rightHipPower,leftKneePower,rightKneePower,leftAnklePower,rightAnklePower,lumbarPower;
      output SI.Power totalStiffnessModulationPower;

      output SI.Force cutForcesWorld[7,3] "Left ankle,knee,hip; right ankle,knee,hip; lumbar";
      output SI.Torque cutMomentsWorld[7,3];
      output SI.Power powerIntoProximalCut[7],powerToDistalBody[7],cutPowerClosure[7];
      output SI.Position segmentCOMWorld[8,3] "Pelvis,trunk,left thigh/shank/foot,right thigh/shank/foot";
      output SI.Position representedCOMWorld[3];
      output SI.Velocity representedCOMVelocity[3];
      output SI.Acceleration representedCOMAcceleration[3];
      output SI.Angle pelvisYawWorld,thoraxYawWorld;
      output Boolean pelvisYawValid,thoraxYawValid;
      output SI.Position leftToeWorld[3]=leftFoot.frame_toe.r_0;
      output SI.Position rightToeWorld[3]=rightFoot.frame_toe.r_0;
      parameter SI.Angle restAngles[15]={-0.007051898347754103,-0.05616621149897582,-0.0408266154749981,0.005876581951724801,-0.003525949171034881,-0.115275665089173,0.5320759336827905,-0.2669810911015702,0.1301746337389886,0.6048192081043453,0.294847674871562,0.115275665089173,0,-0.007052196139056831,0};
      parameter SI.RotationalSpringConstant stiffness[15]={1000,1000,20,1200,2000,2000,25,20,4,20,10,10,1000,1000,20};
      parameter SI.RotationalDampingConstant damping[15]={60,60,2,60,100,100,1.5,2,1.5,1,1,1,50,50,1};
      input SI.Torque ankleActuation;
      input SI.Torque hipYawActuation;
      output SI.Position freeHipWorld[3]=rightHip.frame_a.r_0;
      output SI.Position freeFootWorld[3]=rightFoot.frame_ankle.r_0;
      output SI.Position freeFootRelativePelvis[3]=Modelica.Mechanics.MultiBody.Frames.resolve2(
        pelvis.frame_lumbosacral.R,freeFootWorld-freeHipWorld);
      output SI.Length freeHipToFoot=sqrt(sum((freeFootWorld-freeHipWorld).^2));
      output SI.Length freeSoleHeight[6]={rightPlantarFrames[i].r_0[3] for i in 1:6};
      output SI.Angle allQ[15]=cat(1,leftQ,rightQ,lumbarQ);
      output SI.AngularVelocity allW[15]=cat(1,leftW,rightW,lumbarW);
      output SI.Energy kineticEnergy,potentialEnergy,elasticEnergy,mechanicalEnergy;
      output SI.RotationalSpringConstant actualStiffness[15];
      output SI.RotationalDampingConstant actualDamping[15];
      output SI.Power actuatorPower=ankleActuation*leftW[5]+hipYawActuation*leftW[3];
      output SI.Power dissipationPower;
      output SI.Power modulationPowerIntoStorage=-totalStiffnessModulationPower;
    protected
      SI.AngularVelocity omegaLocal[8,3];
      SI.Velocity segmentVelocity[8,3]=der(segmentCOMWorld);
      parameter SI.Inertia tensors[8,3,3]=cat(1,
        {pelvicProps.I_CM},{thoraxProps.I_CM},
        {diagonal({thighProps.ISagittal,thighProps.ITransverse,thighProps.ILongitudinal})},
        {diagonal({shankProps.ISagittal,shankProps.ITransverse,shankProps.ILongitudinal})},
        {diagonal({footProps.ILongitudinal,footProps.ITransverse,footProps.ISagittal})},
        {diagonal({thighProps.ISagittal,thighProps.ITransverse,thighProps.ILongitudinal})},
        {diagonal({shankProps.ISagittal,shankProps.ITransverse,shankProps.ILongitudinal})},
        {diagonal({footProps.ILongitudinal,footProps.ITransverse,footProps.ISagittal})});
      Real pelvisForwardWorld[3],thoraxForwardWorld[3];
      parameter SI.Mass segmentMasses[8]={pelvicProps.mass,thoraxProps.mass,
        thighProps.mass,shankProps.mass,footProps.mass,thighProps.mass,shankProps.mass,footProps.mass};
      Real leftHipKScale[3],leftHipCScale[3],leftHipKRate[3];
      Real rightHipKScale[3],rightHipCScale[3],rightHipKRate[3];
      Real lumbarKScale[3],lumbarCScale[3],lumbarKRate[3];
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties thighProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Thigh);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties shankProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Shank);
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties footProps=ModelicaHumanBodyPArts.Scaling.resolveSegment(profile,ModelicaHumanBodyPArts.Types.SegmentKey.Foot);
      ModelicaHumanBodyPArts.AxialBody.PelvicRing pelvis(props=pelvicProps,hipCenterDistance=profile.hipCenterDistance,lumbosacralToHipVertical=lumbosacralToHipVertical,animation=animation);
      ModelicaHumanBodyPArts.Transmission.LumbarSpine3D lumbar(mobility=lumbarMobility,q_start=lumbarStart,q_fixed=lumbarFixed,w_start=lumbarWStart,w_fixed=lumbarWFixed,kBase=stiffness[13:15],cBase=damping[13:15],qNeutral=restAngles[13:15]);
      ModelicaHumanBodyPArts.AxialBody.Thorax thorax(props=thoraxProps,shoulderWidth=shoulderWidth,shoulderHeight=shoulderHeight,animation=animation);
      HipDrive leftHip(mobility=hipMobility,isLeft=true,q_start=leftHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=stiffness[1:3],cBase=damping[1:3],qNeutral=restAngles[1:3]);
      ModelicaHumanBodyPArts.Transmission.Hip rightHip(mobility=hipMobility,isLeft=false,q_start=rightHipStart,q_fixed=fill(fixInitialJointCoordinates,3),w_fixed=fill(fixInitialJointVelocities,3),kBase=stiffness[7:9],cBase=damping[7:9],qNeutral=restAngles[7:9]);
      ModelicaHumanBodyPArts.Segments.Thigh leftThigh(props=thighProps,animation=animation),rightThigh(props=thighProps,animation=animation);
      ModelicaHumanBodyPArts.Transmission.Knee leftKnee(mobility=kneeMobility,phi_start=leftKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=stiffness[4],cBase=damping[4],qNeutral=restAngles[4]);
      ModelicaHumanBodyPArts.Transmission.Knee rightKnee(mobility=kneeMobility,phi_start=rightKneeStart,phi_fixed=fixInitialJointCoordinates,w_fixed=fixInitialJointVelocities,kBase=stiffness[10],cBase=damping[10],qNeutral=restAngles[10]);
      ModelicaHumanBodyPArts.Segments.Shank leftShank(props=shankProps,animation=animation),rightShank(props=shankProps,animation=animation);
      AnkleDrive leftAnkle(mobility=ankleMobility,isLeft=true,q_start=leftAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=stiffness[5:6],cBase=damping[5:6],qNeutral=restAngles[5:6]);
      ModelicaHumanBodyPArts.Transmission.AnkleComplex rightAnkle(mobility=ankleMobility,isLeft=false,q_start=rightAnkleStart,q_fixed=fill(fixInitialJointCoordinates,2),w_fixed=fill(fixInitialJointVelocities,2),kBase=stiffness[11:12],cBase=damping[11:12],qNeutral=restAngles[11:12]);
      ModelicaHumanBodyPArts.Segments.Foot leftFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=true);
      ModelicaHumanBodyPArts.Segments.Foot rightFoot(props=footProps,footWidth=profile.footWidth,ankleFromHeel=profile.ankleFromHeel,ankleHeight=profile.ankleHeight,comAboveSole=footCOMAboveSole,comOffsetSourceId=footCOMOffsetSourceId,animation=animation,isLeft=false);
    equation
      leftAnkle.drive={ankleActuation,0};
      leftHip.drive={0,0,hipYawActuation};
      omegaLocal[1,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(pelvis.frame_lumbosacral.R);
      omegaLocal[2,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(thorax.frame_lumbar.R);
      omegaLocal[3,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(leftThigh.frame_proximal.R);
      omegaLocal[4,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(leftShank.frame_proximal.R);
      omegaLocal[5,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(leftFoot.frame_ankle.R);
      omegaLocal[6,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(rightThigh.frame_proximal.R);
      omegaLocal[7,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(rightShank.frame_proximal.R);
      omegaLocal[8,:]=Modelica.Mechanics.MultiBody.Frames.angularVelocity2(rightFoot.frame_ankle.R);
      kineticEnergy=sum({0.5*segmentMasses[i]*sum(segmentVelocity[i,:].^2)
        +0.5*omegaLocal[i,:]*tensors[i,:,:]*omegaLocal[i,:] for i in 1:8});
      potentialEnergy=9.81*sum({segmentMasses[i]*segmentCOMWorld[i,3] for i in 1:8});
      actualStiffness=cat(1,stiffness[1:3].*leftHipKScale,{stiffness[4]},stiffness[5:6],stiffness[7:9].*rightHipKScale,{stiffness[10]},stiffness[11:12],stiffness[13:15].*lumbarKScale);
      actualDamping=cat(1,damping[1:3].*leftHipCScale,{damping[4]},damping[5:6],damping[7:9].*rightHipCScale,{damping[10]},damping[11:12],damping[13:15].*lumbarCScale);
      elasticEnergy=0.5*sum(actualStiffness.*(allQ-restAngles).^2);
      dissipationPower=sum(actualDamping.*allW.^2);
      mechanicalEnergy=kineticEnergy+potentialEnergy+elasticEnergy;
      cutForcesWorld[1,:]=leftAnkle.cutForceWorld;
      cutMomentsWorld[1,:]=leftAnkle.cutMomentWorld;
      powerIntoProximalCut[1]=leftAnkle.cutPowerIntoA;
      powerToDistalBody[1]=leftAnkle.powerToDistalBody;
      cutPowerClosure[1]=leftAnkle.cutPowerClosure;
      cutForcesWorld[2,:]=leftKnee.cutForceWorld;
      cutMomentsWorld[2,:]=leftKnee.cutMomentWorld;
      powerIntoProximalCut[2]=leftKnee.cutPowerIntoA;
      powerToDistalBody[2]=leftKnee.powerToDistalBody;
      cutPowerClosure[2]=leftKnee.cutPowerClosure;
      cutForcesWorld[3,:]=leftHip.cutForceWorld;
      cutMomentsWorld[3,:]=leftHip.cutMomentWorld;
      powerIntoProximalCut[3]=leftHip.cutPowerIntoA;
      powerToDistalBody[3]=leftHip.powerToDistalBody;
      cutPowerClosure[3]=leftHip.cutPowerClosure;
      cutForcesWorld[4,:]=rightAnkle.cutForceWorld;
      cutMomentsWorld[4,:]=rightAnkle.cutMomentWorld;
      powerIntoProximalCut[4]=rightAnkle.cutPowerIntoA;
      powerToDistalBody[4]=rightAnkle.powerToDistalBody;
      cutPowerClosure[4]=rightAnkle.cutPowerClosure;
      cutForcesWorld[5,:]=rightKnee.cutForceWorld;
      cutMomentsWorld[5,:]=rightKnee.cutMomentWorld;
      powerIntoProximalCut[5]=rightKnee.cutPowerIntoA;
      powerToDistalBody[5]=rightKnee.powerToDistalBody;
      cutPowerClosure[5]=rightKnee.cutPowerClosure;
      cutForcesWorld[6,:]=rightHip.cutForceWorld;
      cutMomentsWorld[6,:]=rightHip.cutMomentWorld;
      powerIntoProximalCut[6]=rightHip.cutPowerIntoA;
      powerToDistalBody[6]=rightHip.powerToDistalBody;
      cutPowerClosure[6]=rightHip.cutPowerClosure;
      cutForcesWorld[7,:]=lumbar.cutForceWorld;
      cutMomentsWorld[7,:]=lumbar.cutMomentWorld;
      powerIntoProximalCut[7]=lumbar.cutPowerIntoA;
      powerToDistalBody[7]=lumbar.powerToDistalBody;
      cutPowerClosure[7]=lumbar.cutPowerClosure;
      segmentCOMWorld[1,:]=pelvis.frame_lumbosacral.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(pelvis.frame_lumbosacral.R,pelvicProps.rCM);
      segmentCOMWorld[2,:]=thorax.frame_lumbar.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(thorax.frame_lumbar.R,thoraxProps.rCM);
      segmentCOMWorld[3,:]=leftThigh.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(leftThigh.frame_proximal.R,{0,0,-thighProps.comDistance});
      segmentCOMWorld[4,:]=leftShank.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(leftShank.frame_proximal.R,{0,0,-shankProps.comDistance});
      segmentCOMWorld[5,:]=leftFoot.frame_ankle.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(leftFoot.frame_ankle.R,leftFoot.comPositionLocal);
      segmentCOMWorld[6,:]=rightThigh.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(rightThigh.frame_proximal.R,{0,0,-thighProps.comDistance});
      segmentCOMWorld[7,:]=rightShank.frame_proximal.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(rightShank.frame_proximal.R,{0,0,-shankProps.comDistance});
      segmentCOMWorld[8,:]=rightFoot.frame_ankle.r_0+Modelica.Mechanics.MultiBody.Frames.resolve1(rightFoot.frame_ankle.R,rightFoot.comPositionLocal);
      for j in 1:3 loop
        representedCOMWorld[j]=sum({segmentMasses[i]*segmentCOMWorld[i,j] for i in 1:8})/representedMass;
      end for;
      representedCOMVelocity=der(representedCOMWorld);
      representedCOMAcceleration=der(representedCOMVelocity);
      pelvisForwardWorld=Modelica.Mechanics.MultiBody.Frames.resolve1(pelvis.frame_lumbosacral.R,{1,0,0});
      thoraxForwardWorld=Modelica.Mechanics.MultiBody.Frames.resolve1(thorax.frame_lumbar.R,{1,0,0});
      pelvisYawValid=pelvisForwardWorld[1]^2+pelvisForwardWorld[2]^2>1e-12;
      thoraxYawValid=thoraxForwardWorld[1]^2+thoraxForwardWorld[2]^2>1e-12;
      pelvisYawWorld=atan2(pelvisForwardWorld[2],pelvisForwardWorld[1]);
      thoraxYawWorld=atan2(thoraxForwardWorld[2],thoraxForwardWorld[1]);
      connect(frame_pelvisReference,pelvis.frame_lumbosacral); connect(pelvis.frame_lumbosacral,lumbar.frame_pelvis); connect(lumbar.frame_thorax,thorax.frame_lumbar); connect(thorax.frame_cervical,frame_cervical);
      connect(pelvis.frame_leftHip,leftHip.frame_a); connect(leftHip.frame_b,leftThigh.frame_proximal); connect(leftThigh.frame_distal,leftKnee.frame_a); connect(leftKnee.frame_b,leftShank.frame_proximal); connect(leftShank.frame_distal,leftAnkle.frame_a); connect(leftAnkle.frame_b,leftFoot.frame_ankle); connect(leftFoot.frame_ankle,leftFootReference);
      connect(pelvis.frame_rightHip,rightHip.frame_a); connect(rightHip.frame_b,rightThigh.frame_proximal); connect(rightThigh.frame_distal,rightKnee.frame_a); connect(rightKnee.frame_b,rightShank.frame_proximal); connect(rightShank.frame_distal,rightAnkle.frame_a); connect(rightAnkle.frame_b,rightFoot.frame_ankle); connect(rightFoot.frame_ankle,rightFootReference);
      for i in 1:6 loop connect(leftFoot.frame_plantar[i],leftPlantarFrames[i]); connect(rightFoot.frame_plantar[i],rightPlantarFrames[i]); end for;
      if useVariableImpedance then
        leftHipKScale=leftHipControl[1:3]; leftHipCScale=leftHipControl[4:6]; leftHipKRate=leftHipControl[7:9];
        rightHipKScale=rightHipControl[1:3]; rightHipCScale=rightHipControl[4:6]; rightHipKRate=rightHipControl[7:9];
        lumbarKScale=lumbarControl[1:3]; lumbarCScale=lumbarControl[4:6]; lumbarKRate=lumbarControl[7:9];
      else
        leftHipKScale=fill(1,3); leftHipCScale=fill(1,3); leftHipKRate=zeros(3);
        rightHipKScale=fill(1,3); rightHipCScale=fill(1,3); rightHipKRate=zeros(3);
        lumbarKScale=fill(1,3); lumbarCScale=fill(1,3); lumbarKRate=zeros(3);
      end if;
      leftHip.stiffnessScale=leftHipKScale; leftHip.dampingScale=leftHipCScale; leftHip.stiffnessScaleRate=leftHipKRate;
      rightHip.stiffnessScale=rightHipKScale; rightHip.dampingScale=rightHipCScale; rightHip.stiffnessScaleRate=rightHipKRate;
      leftKnee.stiffnessScale=1; leftKnee.dampingScale=1; leftKnee.stiffnessScaleRate=0;
      rightKnee.stiffnessScale=1; rightKnee.dampingScale=1; rightKnee.stiffnessScaleRate=0;
      leftAnkle.stiffnessScale=fill(1,2); leftAnkle.dampingScale=fill(1,2); leftAnkle.stiffnessScaleRate=zeros(2);
      rightAnkle.stiffnessScale=fill(1,2); rightAnkle.dampingScale=fill(1,2); rightAnkle.stiffnessScaleRate=zeros(2);
      lumbar.stiffnessScale=lumbarKScale; lumbar.dampingScale=lumbarCScale; lumbar.stiffnessScaleRate=lumbarKRate;
      leftQ=cat(1,leftHip.q,{leftKnee.q},leftAnkle.q); rightQ=cat(1,rightHip.q,{rightKnee.q},rightAnkle.q); lumbarQ=lumbar.q;
      leftW=cat(1,leftHip.w,{leftKnee.w},leftAnkle.w); rightW=cat(1,rightHip.w,{rightKnee.w},rightAnkle.w); lumbarW=lumbar.w;
      representedMass=pelvicProps.mass+thoraxProps.mass+2*(thighProps.mass+shankProps.mass+footProps.mass);
      leftHipReactionForce=leftHip.reactionForce; rightHipReactionForce=rightHip.reactionForce; leftKneeReactionForce=leftKnee.reactionForce; rightKneeReactionForce=rightKnee.reactionForce; leftAnkleReactionForce=leftAnkle.reactionForce; rightAnkleReactionForce=rightAnkle.reactionForce; lumbosacralForce=lumbar.reactionForce;
      leftHipReactionMoment=leftHip.reactionMoment; rightHipReactionMoment=rightHip.reactionMoment; leftKneeReactionMoment=leftKnee.reactionMoment; rightKneeReactionMoment=rightKnee.reactionMoment; leftAnkleReactionMoment=leftAnkle.reactionMoment; rightAnkleReactionMoment=rightAnkle.reactionMoment; lumbosacralMoment=lumbar.reactionMoment;
      leftHipTorque=leftHip.generalizedTorque; rightHipTorque=rightHip.generalizedTorque; leftKneeTorque=leftKnee.generalizedTorque; rightKneeTorque=rightKnee.generalizedTorque; leftAnkleTorque=leftAnkle.generalizedTorque; rightAnkleTorque=rightAnkle.generalizedTorque; lumbarTorque=lumbar.generalizedTorque;
      leftHipPower=leftHip.generalizedPower; rightHipPower=rightHip.generalizedPower; leftKneePower=leftKnee.generalizedPower; rightKneePower=rightKnee.generalizedPower; leftAnklePower=leftAnkle.generalizedPower; rightAnklePower=rightAnkle.generalizedPower; lumbarPower=lumbar.generalizedPower;
      totalStiffnessModulationPower=leftHip.stiffnessModulationPower+rightHip.stiffnessModulationPower+leftKnee.stiffnessModulationPower+rightKnee.stiffnessModulationPower+leftAnkle.stiffnessModulationPower+rightAnkle.stiffnessModulationPower+lumbar.stiffnessModulationPower;
      annotation(Documentation(info="<html><p>This v0.9.1 assembly exposes cut reaction wrenches at ankle, knee, hip and lumbosacral interfaces and generalized torque/power for the explicit impedance coordinates. It still does not identify individual muscles or cartilage contact stress.</p></html>"));
    end LoadedSupportBody;

    model M2bLoadedSupport
      "Loaded single support: ankle pitch + stance hip yaw; external reactions solved, not imposed"
      import SI=Modelica.Units.SI;
      parameter Boolean shearEnabled=true,yawEnabled=true;
      parameter SI.Torque anklePulse=15,hipYawPulse=4;
      parameter Real mu(min=0)=0.6;
      parameter Boolean enforceNecessaryContactGate=true;
      inner Modelica.Mechanics.MultiBody.World world(n={0,0,-1},g=9.81,
        gravityType=Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity,enableAnimation=false);
      parameter ModelicaHumanBodyPArts.Records.AnthropometryProfile profile(height=1.75,mass=75,
        sex=ModelicaHumanBodyPArts.Types.Sex.Male,footLength=0.26,footWidth=0.095,
        ankleFromHeel=0.07,ankleHeight=0.08,shankLength=0.43,thighLength=0.44,
        pelvisLength=0.18,hipCenterDistance=0.20,geometrySourceId="SYNTHETIC_M2B_FIXTURE");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D pp(mass=8,length=0.18,
        rCM={0,0,-0.05},I_CM={{0.1,0,0},{0,0.08,0},{0,0,0.06}},R_principal=identity(3),
        segmentFrameId="SYNTHETIC_M2B_PELVIS");
      parameter ModelicaHumanBodyPArts.Records.SegmentProperties3D tp(mass=25,length=0.5,
        rCM={0,0,0.25},I_CM={{1.2,0,0},{0,0.9,0},{0,0,1}},R_principal=identity(3),
        segmentFrameId="SYNTHETIC_M2B_UPPER_TRUNK");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile hipROM(n=3,
        qMin={-0.5,-0.7,-0.7},qMax={2.2,0.7,0.7},sourceId="SYNTHETIC_M2B_ROM_GATE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile kneeROM(n=1,
        qMin={-0.15},qMax={2.8},sourceId="SYNTHETIC_M2B_ROM_GATE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile ankleROM(n=2,
        qMin={-0.8,-0.6},qMax={0.8,0.6},sourceId="SYNTHETIC_M2B_ROM_GATE");
      parameter ModelicaHumanBodyPArts.Records.JointMobilityProfile lumbarROM(n=3,
        qMin=fill(-0.5,3),qMax=fill(0.5,3),sourceId="SYNTHETIC_M2B_ROM_GATE");
      parameter SI.Angle initialQ[15]={0,0,0,0,0,-0.115275665089173,0.25,0,0,0.5,0.25,0.115275665089173,0,0,0};
      Modelica.Mechanics.MultiBody.Parts.Fixed support(r={0,0,0.08},animation=false);
      SmoothSupportPulse pulse;
      LoadedSupportBody body(profile=profile,pelvicProps=pp,thoraxProps=tp,
        lumbosacralToHipVertical=0.1,shoulderWidth=0.4,footCOMAboveSole=0.035,
        footCOMOffsetSourceId="SYNTHETIC_M2B_OFFSET",hipMobility=hipROM,kneeMobility=kneeROM,
        ankleMobility=ankleROM,lumbarMobility=lumbarROM,leftHipStart=initialQ[1:3],
        leftKneeStart=initialQ[4],leftAnkleStart=initialQ[5:6],rightHipStart=initialQ[7:9],
        rightKneeStart=initialQ[10],rightAnkleStart=initialQ[11:12],lumbarStart=initialQ[13:15],
        fixInitialJointCoordinates=true,fixInitialJointVelocities=true,
        lumbarFixed=fill(true,3),lumbarWFixed=fill(true,3),animation=false);
      output SI.Force groundForce[3]=-support.frame_b.f;
      output SI.Torque groundMoment[3]=-support.frame_b.t+cross({0,0,0.08},groundForce);
      output SI.Force footOnGroundForce[3]=-groundForce;
      output SI.Position cop[2];
      output Real frictionUtilization;
      output Boolean necessaryContactGate;
      output SI.Force forceBalanceResidual[3];
      output SI.Length freeFootWorldDelta[3]=body.freeFootWorld-freeWorld0;
      output SI.Length freeFootRelativeDelta[3]=body.freeFootRelativePelvis-freeRelative0;
      output SI.Length freeHipFootChange=body.freeHipToFoot-freeDistance0;
      output SI.Velocity freeFootWorldVelocity[3]=der(body.freeFootWorld);
      output SI.Length minFreeSoleClearance=min(body.freeSoleHeight);
      output SI.Angle pelvisYaw=body.pelvisYawWorld,thoraxYaw=body.thoraxYawWorld;
      output SI.Angle lumbarAxial=body.lumbarQ[3],freeHipFlexion=body.rightQ[1],freeKnee=body.rightQ[4];
      output SI.Energy actuatorWork(start=0,fixed=true),dampingLoss(start=0,fixed=true);
      output SI.Energy energyBalanceResidual=body.mechanicalEnergy-energy0+dampingLoss-actuatorWork;
      output Integer checksPassed(start=0,fixed=true);
    protected
      parameter SI.Position freeWorld0[3](each fixed=false),freeRelative0[3](each fixed=false);
      parameter SI.Length freeDistance0(fixed=false);
      parameter SI.Energy energy0(fixed=false);
    initial equation
      freeWorld0=body.freeFootWorld;freeRelative0=body.freeFootRelativePelvis;
      freeDistance0=body.freeHipToFoot;energy0=body.mechanicalEnergy;
    equation
      connect(support.frame_b,body.leftFootReference);
      body.ankleActuation=if shearEnabled then anklePulse*pulse.y else 0;
      body.hipYawActuation=if yawEnabled then hipYawPulse*pulse.y else 0;
      cop=if groundForce[3]>1e-6 then {-groundMoment[2],groundMoment[1]}/groundForce[3] else {0,0};
      frictionUtilization=sqrt(groundForce[1]^2+groundForce[2]^2)/max(mu*groundForce[3],1e-6);
      necessaryContactGate=groundForce[3]>0 and cop[1]>=-0.07 and cop[1]<=0.19
        and abs(cop[2])<=0.0475 and frictionUtilization<=1;
      forceBalanceResidual=groundForce+{0,0,-9.81*body.representedMass}
        -body.representedMass*body.representedCOMAcceleration;
      der(actuatorWork)=body.actuatorPower;der(dampingLoss)=body.dissipationPower;
      assert(not enforceNecessaryContactGate or necessaryContactGate,
        "Required rigid-contact force/COP/friction gate failed; this is not a valid stance sample");
      assert(minFreeSoleClearance>=-1e-6,"Free-foot clearance violated; no impact model is present");
    algorithm
      when time>=0.74 then
        assert(max(abs(forceBalanceResidual))<1e-4,"Whole represented-body force balance failed");
        assert(abs(energyBalanceResidual)<1e-3,"Energy balance with explicit actuator work failed");
        checksPassed:=1;
      end when;
      annotation(experiment(StopTime=0.75,Interval=0.0025,Tolerance=1e-8),
        Documentation(info="<html><p>New gravity-loaded functional fixture, not a complete dance or a human validation. Stationary rigid foot constraint is admissible only when the returned contact wrench is feasible. A separate corner-force friction-cone test is required in addition to the necessary in-model gates. External Fx, Mz and Fz are measured reactions; only ankle-pitch and stance-hip-yaw torque pulses are commanded. Free-leg joints have fixed passive preloads derived from initial gravity equilibrium; no free target, controller or active source. Initial posture/preloads are synthetic and not physiological measurements. Free-leg forward response is not an assertion: zero, backward or inferior outcomes must remain reported.</p></html>"));
    end M2bLoadedSupport;
    model M2bBaseline
      extends M2bLoadedSupport(shearEnabled=false,yawEnabled=false);
    end M2bBaseline;
    model M2bShearOnly
      extends M2bLoadedSupport(shearEnabled=true,yawEnabled=false);
    end M2bShearOnly;
    model M2bYawOnly
      extends M2bLoadedSupport(shearEnabled=false,yawEnabled=true);
    end M2bYawOnly;
    model M2bCombined
      extends M2bLoadedSupport(shearEnabled=true,yawEnabled=true);
    end M2bCombined;
  end SupportInitiation;

end ModelicaHumanBodyPArts;
