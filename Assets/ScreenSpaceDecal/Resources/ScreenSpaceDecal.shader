// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Image Effects/ScreenSpaceDecal"
{
	Properties
	{
		_DecalXZAndInvSize0 ("_DecalXZAndInvSize0", vector) = (0,0,1,1)
		_DecalOffset0 ("_DecalOffset0", vector) = (0,0,0,0)
		_DecalXZAndInvSize1 ("_DecalXZAndInvSize1", vector) = (0,0,1,1)
		_DecalOffset1 ("_DecalOffset1", vector) = (0,0,0,0)
		_DecalXZAndInvSize2 ("_DecalXZAndInvSize2", vector) = (0,0,1,1)
		_DecalOffset2 ("_DecalOffset2", vector) = (0,0,0,0)
		_DecalTex ("_DecalTex", 2D) = "black" {}
		[HideInInspector]
		_MainTex ("Screen Blended", 2D) = "" {}
	}

	CGINCLUDE
		#include "UnityCG.cginc"


#define DECAL_VAR(n) \
		uniform float4 _DecalXZAndInvSize##n;\
		uniform float4 _DecalOffset##n;
		
		uniform sampler2D_float _CameraDepthTexture;
		uniform float4x4 _InverseMVP;
		DECAL_VAR(0)
		DECAL_VAR(1)
		DECAL_VAR(2)
		uniform sampler2D _DecalTex;
		uniform float4 _DecalTex_ST;
		uniform	sampler2D _MainTex;
		uniform half4 _MainTex_TexelSize;

		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;

		#if UNITY_UV_STARTS_AT_TOP
			float2 uv2 : TEXCOORD1;
		#endif
		};	
		
		v2f vert ( appdata_img v)
		{
			v2f o;
			
			o.pos = UnityObjectToClipPos (v.vertex);
        	o.uv = v.texcoord;		
        	
		#if UNITY_UV_STARTS_AT_TOP
        	o.uv2 = v.texcoord;		
			//_TexelSize.y is negative when it belongs to RenderTexture that has been flipped vertically by D3D anti-aliasing.
			//[from:https//forum.unity3d.com]		
        	if (_MainTex_TexelSize.y < 0.0)
        		o.uv2.y = 1.0 - o.uv2.y;
		#endif
        	        	
			return o; 
		}

		float3 CamToWorld (in half2 uv, in float depth)
		{
			float4 pos = float4(uv.x, uv.y, depth, 1.0);
			pos.xyz = pos.xyz * 2.0 - 1.0;
			pos.z = -pos.z;
			pos = mul(_InverseMVP, pos);
			return pos.xyz / pos.w;
		}

#define BLEND_DECAL(n) \
		{ \
			float2 deltaPos = pos.xz - _DecalXZAndInvSize##n.xy; \
			float2 duv = (deltaPos + float2(0.5,0.5)) * _DecalXZAndInvSize##n.zw; \
			if (duv.x > 0 && duv.y > 0 && duv.x < 1 && duv.y < 1) \
			{ \
				_DecalTex_ST.zw = _DecalOffset##n.xy; \
				duv = TRANSFORM_TEX(duv, _DecalTex); \
				half4 dec = tex2D(_DecalTex, duv); \
				col = lerp(col, dec, dec.a); \
			} \
		}

		fixed4 frag (v2f i) : COLOR
		{
		#if UNITY_UV_STARTS_AT_TOP
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv2);
		#else
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
		#endif
			float3 pos = CamToWorld(i.uv, depth);

			// // Limit the fog of war to sea level
			// if (pos.y < 0.0)
			// {
			// 	// This is a simplified version of the ray-plane intersection formula: t = -( N.O + d ) / ( N.D )
			// 	half3 dir = normalize(pos.xyz - _WorldSpaceCameraPos.xyz);
			// 	pos.xyz = _WorldSpaceCameraPos.xyz - dir * (_WorldSpaceCameraPos.y / dir.y);
			// }
			half4 col = tex2D(_MainTex, i.uv);
			BLEND_DECAL(0);
			BLEND_DECAL(1);
			BLEND_DECAL(2);
			return col;
		}


	ENDCG

	SubShader
	{
		ZTest Off Cull Off ZWrite Off Blend Off Fog { Mode off }

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
		ENDCG
		}
	}
	Fallback off
}