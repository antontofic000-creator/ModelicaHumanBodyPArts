within ModelicaHumanBodyPArts;
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

