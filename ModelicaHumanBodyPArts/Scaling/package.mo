within ModelicaHumanBodyPArts;
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

