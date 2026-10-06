within;
package Article2ReproductionTests
  "Study-level wrappers around the immutable Article 2 experiment sources"
  model PrimaryLocked
    extends ModelicaHumanBodyPArtsArticle2.DistributedSupport(architecture=1,rightStance=true,ankleAmplitude=15,hipAmplitude=-1,hold=0.6,fall=0.2,impedanceMode=0,freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
    annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
  end PrimaryLocked;
  model PrimaryYawOnly
    extends ModelicaHumanBodyPArtsArticle2.DistributedSupport(architecture=2,rightStance=true,ankleAmplitude=15,hipAmplitude=-1,hold=0.6,fall=0.2,impedanceMode=0,freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
    annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
  end PrimaryYawOnly;
  model PrimaryFull3D
    extends ModelicaHumanBodyPArtsArticle2.DistributedSupport(architecture=3,rightStance=true,ankleAmplitude=15,hipAmplitude=-1,hold=0.6,fall=0.2,impedanceMode=0,freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
    annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
  end PrimaryFull3D;
  model UpperBodyKnownAnswer
    extends ModelicaHumanBodyPArtsArticle2UpperBody.UpperBodyInertiaKnownAnswer;
  end UpperBodyKnownAnswer;
  model UpperBodyLocked
    extends ModelicaHumanBodyPArtsArticle2UpperBody.DistributedSupport(architecture=1,rightStance=true,ankleAmplitude=15,hipAmplitude=-1,hold=0.6,fall=0.2,impedanceMode=0,freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
    annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
  end UpperBodyLocked;
  model UpperBodyYawOnly
    extends ModelicaHumanBodyPArtsArticle2UpperBody.DistributedSupport(architecture=2,rightStance=true,ankleAmplitude=15,hipAmplitude=-1,hold=0.6,fall=0.2,impedanceMode=0,freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
    annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
  end UpperBodyYawOnly;
  model UpperBodyFull3D
    extends ModelicaHumanBodyPArtsArticle2UpperBody.DistributedSupport(architecture=3,rightStance=true,ankleAmplitude=15,hipAmplitude=-1,hold=0.6,fall=0.2,impedanceMode=0,freeQ0={0.25,0,0,0.5,-0.03,0.115275665089173},endTime=1.5);
    annotation(experiment(StartTime=0,StopTime=1.5,Tolerance=1e-8,Interval=0.002));
  end UpperBodyFull3D;
  annotation(uses(Modelica(version="4.1.0"),ModelicaHumanBodyPArts(version="0.10.0")));
end Article2ReproductionTests;
