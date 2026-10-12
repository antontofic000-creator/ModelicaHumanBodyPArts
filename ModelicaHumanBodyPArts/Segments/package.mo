within ModelicaHumanBodyPArts;
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

