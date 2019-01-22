#Ifndef ACTOR_SIMULATIONINTERFACE_BI
#Define ACTOR_SIMULATIONINTERFACE_BI

#Include "../actor.bi"
#Include "../physics.bi"

Namespace act
	
Type SimulationInterface Extends Actor
 Public:
 	ACTOR_REQUIRED_DECL(SimulationInterface)
 
	Declare Constructor(parent As ActorBankFwd Ptr, simulation As Simulation Ptr)
	
	Declare Sub setForce(ByRef f As Const Vec2F)
	
 	Declare Function clone(parent As ActorBankFwd Ptr) As Actor Ptr Override
 Private:
 	As Simulation Ptr sim_
End Type

End Namespace

#EndIf