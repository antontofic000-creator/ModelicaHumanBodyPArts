within ModelicaHumanBodyPArts;
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

