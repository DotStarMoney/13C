#Include "vecmath.bi"

#Include "debuglog.bi"

Namespace vecmath
  
Function dot(ByRef lhs As Const Vec2F, ByRef rhs As Const Vec2F) As Single
  Return lhs.x*rhs.x + lhs.y*rhs.y
End Function

Function dot(ByRef lhs As Const Vec3F, ByRef rhs As Const Vec3F) As Single
  Return lhs.x*rhs.x + lhs.y*rhs.y + lhs.z*rhs.z
End Function

Function cross(ByRef lhs As Const Vec2F, ByRef rhs As Const Vec2F) As Single
  Return lhs.x*rhs.y - rhs.x*lhs.y
End Function

Function cross(ByRef lhs As Const Vec3F, ByRef rhs As Const Vec3F) As Vec3F
  Return Vec3f(lhs.y*rhs.z - lhs.z*rhs.y, lhs.z*rhs.x - lhs.x*rhs.z, lhs.x*rhs.y - lhs.y*rhs.x)
End Function

Sub normalize(v As Vec2F Const Ptr)
  Dim As Single m = v->m()
  DEBUG_ASSERT(m <> 0.0f)
  *v /= m
End Sub

Sub normalize(v As Vec3F Const Ptr)
  Dim As Single m = v->m()
  DEBUG_ASSERT(m <> 0.0f)
  *v /= m
End Sub

Sub maxsat(v As Vec2F Const Ptr)
	v->x = IIf(v->x > 1, 1, v->x)
	v->y = IIf(v->y > 1, 1, v->y)
End Sub

Sub maxsat(v As Vec3F Const Ptr)
	v->x = IIf(v->x > 1, 1, v->x)
	v->y = IIf(v->y > 1, 1, v->y)
	v->z = IIf(v->z > 1, 1, v->z)
End Sub

End Namespace
