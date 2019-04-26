Shader "LightingShader" {
	Properties{
		 //Parameters for the texture and the normal map
		_Tex1("Base (RGB)", 2D) = "black" {}
		_Tex2("Texture", 2D) = "bump" {}

		// Ambient light value
		_ambientLight("Ambient Light", Float) = 0.01

			// Colour of the main directional light
			_lightColour("Light Colour", Color) = (255, 255, 255, 1)

			// Parameters of the main directional light
			_vecLightPos("Light Position", Vector) = (12.0, 12.0, 0.0, 0.0)
			_lightIntensity("Light Intensity", Float) = 0.75

			// Parameters of the first spot light
			_vecSpotLight0Pos("Spot Light 1 Position", Vector) = (12.0, 12.0, 0.0, 0.0)
			_vecSpotLight0Dir("Spot Light 1 Direction", Vector) = (-0.33, -0.77, 0.56, 0.0)
			_spotLight0Angle("Spot Light 1 Angle", Float) = 30
			_spotLight0Intensity("Spot Light 1 Intensity", Float) = 5.0

			// Parameters of the second spot light
			_vecSpotLight1Pos("Spot Light 2 Position", Vector) = (12.0, 12.0, 0.0, 0.0)
			_vecSpotLight1Dir("Spot Light 2 Direction", Vector) = (-0.33, -0.77, 0.56, 0.0)
			_spotLight1Angle("Spot Light 2 Angle", Float) = 30
			_spotLight1Intensity("Spot Light 2 Intensity", Float) = 5.0

			// Shadow Map Textures
			_ShadowMap("ShadowMap", 2D) = "red"
			_ShadowMapSpot0("ShadowMapSpot0", 2D) = "red"
			_ShadowMapSpot1("ShadowMapSpot1", 2D) = "red"

			// Fire Parameters
			_vecFirePos("Fire Position", Vector) = (0, 0.5, -12)
			_fireIntensity("Fire Intensity", Float) = 2
	}

	SubShader {
		Tags {"RenderType" = "Opaque"}

		Pass {
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex ShaderVS
			#pragma fragment ShaderPS keepalpha
			#pragma target 3.0

			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			// Values for the texture and normal map
			sampler2D _Tex1;
			sampler2D _Tex2;

			// Values for the ambient light
			uniform float _ambientLight;
			uniform float4 _ambLightColour;

			// World position of the camera
			static float3 _vecCameraPos = { 6.115139f, 1.5f, -0.2795348f};

			// Values for the main directional light
			uniform float3 _lightColour;
			uniform float3 _vecLightPos;
			uniform float _lightIntensity;

			// Values for the first spot light
			uniform float3 _vecSpotLight0Pos;
			uniform float3 _vecSpotLight0Dir;
			uniform float _spotLight0Angle;
			uniform float _spotLight0Intensity;

			// Values for the second spot light
			uniform float3 _vecSpotLight1Pos;
			uniform float3 _vecSpotLight1Dir;
			uniform float _spotLight1Angle;
			uniform float _spotLight1Intensity;

			uniform float3 _vecFirePos;
			uniform float _fireIntensity;

			// Output for the texture tiling
			float4 _Tex1_ST;

			// shadow map components
			uniform sampler2D _ShadowMap;
			uniform sampler2D _ShadowMapSpot0;
			uniform sampler2D _ShadowMapSpot1;
			static float _TexSize = 2048;
			static float _Bias = 0.012;
			uniform float4x4  _ProjMatrixSun;
			uniform float4x4  _ProjMatrixSpot0;
			uniform float4x4  _ProjMatrixSpot1;
			static float _FarClip = 60;
			static float _NearClip = 0.3;

			// Vertex shader input structure
			struct VSInput {
				float4 pos: POSITION;
				float4 tang: TANGENT;
				float3 nor: NORMAL;
				float2 tex: TEXCOORD0;
			};

			// Vertex shader output structure
			struct VSOutput {
				float4 pos: SV_POSITION;
				float4 diff : COLOR0;
				float2 tex: TEXCOORD0;
				float3 posWorld: TEXCOORD2;
				float4 projTex: TEXCOORD1;
				float3 nor: TEXCOORD3;
				float4 projTexSpot0: TEXCOORD4;
				float4 projTexSpot1: TEXCOORD5;
			};

			// Vertex shader
			VSOutput ShaderVS(VSInput a_Input) {
				VSOutput output;

				// Calculate homogeneus coordinate positions
				output.pos = UnityObjectToClipPos(a_Input.pos);

				// Copy texture values across
				output.tex = a_Input.tex;

				// Apply texture tiling
				output.tex = TRANSFORM_TEX(a_Input.tex, _Tex1);

				// Calculate parts for the diffuse component
				float3 worldNormal = UnityObjectToWorldNormal(a_Input.nor);
				float nl = max(0, dot(worldNormal, _vecLightPos.xyz));
				output.diff.xyz = nl * _lightColour.xyz;

				// Calculate normal
				output.nor = normalize(mul(transpose(unity_WorldToObject), float4(a_Input.nor, 0.0f))).xyz;

				// Calculate world position
				output.posWorld = mul(unity_ObjectToWorld, a_Input.pos).xyz;

				float4 posWorld = float4(output.posWorld.xyz, 1.0f);

				output.projTex = mul(_ProjMatrixSun, posWorld);
				output.projTexSpot0 = mul(_ProjMatrixSpot0, posWorld);
				output.projTexSpot1 = mul(_ProjMatrixSpot1, posWorld);

				return output;
			}

			// Pixel shader
			fixed4 ShaderPS(VSOutput a_Input) : COLOR {
				// Make sure normal is normalized
				a_Input.nor = normalize(a_Input.nor);

				// Index into textures
				float4 colour = tex2D(_Tex1, a_Input.tex);
				float3 normal = UnpackNormal(tex2D(_Tex2, a_Input.tex)).rgb;

				// transform coordinates into texture coordinates
				a_Input.projTex.xy /= a_Input.projTex.w;
				a_Input.projTex.x = 0.5 * a_Input.projTex.x + 0.5f;
				a_Input.projTex.y = 0.5 * a_Input.projTex.y + 0.5f;
					
				// Compute pixel depth for shadowing
				float depth = a_Input.projTex.z / a_Input.projTex.w;

				// Now linearise using a formula by Humus, drawn from the near and far clipping planes of the camera.
				float sceneDepth = _NearClip * (depth + 1.0) / (_FarClip + _NearClip - depth * (_FarClip - _NearClip));
	
				// Transform to texel space
				float2 texelpos = _TexSize * a_Input.projTex.xy;

				// Determine the lerp amounts.           
				float2 lerps = frac(texelpos);

				// sample shadow map
				float dx = 1.0f / _TexSize;
				float s0 = (DecodeFloatRGBA(tex2D(_ShadowMap, a_Input.projTex.xy)) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				float s1 = (DecodeFloatRGBA(tex2D(_ShadowMap, a_Input.projTex.xy + float2(dx, 0.0f))) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				float s2 = (DecodeFloatRGBA(tex2D(_ShadowMap, a_Input.projTex.xy + float2(0.0f, dx))) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				float s3 = (DecodeFloatRGBA(tex2D(_ShadowMap, a_Input.projTex.xy + float2(dx, dx))) + _Bias < sceneDepth) ? 0.0f : 1.0f;

				float shadowCoeff = lerp(lerp(s0, s1, lerps.x), lerp(s2, s3, lerps.x), lerps.y);

				// transform coordinates into texture coordinates
				a_Input.projTexSpot0.xy /= a_Input.projTexSpot0.w;
				a_Input.projTexSpot0.x = 0.5 * a_Input.projTexSpot0.x + 0.5f;
				a_Input.projTexSpot0.y = 0.5 * a_Input.projTexSpot0.y + 0.5f;

				// Compute pixel depth for shadowing
				depth = a_Input.projTexSpot0.z / a_Input.projTexSpot0.w;

				// Now linearise using a formula by Humus, drawn from the near and far clipping planes of the camera.
				sceneDepth = _NearClip * (depth + 1.0) / (_FarClip + _NearClip - depth * (_FarClip - _NearClip));

				// Transform to texel space
				texelpos = _TexSize * a_Input.projTexSpot0.xy;

				// Determine the lerp amounts.           
				lerps = frac(texelpos);

				// sample shadow map
				dx = 1.0f / _TexSize;
				s0 = (DecodeFloatRGBA(tex2D(_ShadowMapSpot0, a_Input.projTexSpot0.xy)) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				s1 = (DecodeFloatRGBA(tex2D(_ShadowMapSpot0, a_Input.projTexSpot0.xy + float2(dx, 0.0f))) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				s2 = (DecodeFloatRGBA(tex2D(_ShadowMapSpot0, a_Input.projTexSpot0.xy + float2(0.0f, dx))) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				s3 = (DecodeFloatRGBA(tex2D(_ShadowMapSpot0, a_Input.projTexSpot0.xy + float2(dx, dx))) + _Bias < sceneDepth) ? 0.0f : 1.0f;

				float shadowCoeffSpot0 = lerp(lerp(s0, s1, lerps.x), lerp(s2, s3, lerps.x), lerps.y);

				// transform coordinates into texture coordinates
				a_Input.projTexSpot1.xy /= a_Input.projTexSpot1.w;
				a_Input.projTexSpot1.x = 0.5 * a_Input.projTexSpot1.x + 0.5f;
				a_Input.projTexSpot1.y = 0.5 * a_Input.projTexSpot1.y + 0.5f;

				// Compute pixel depth for shadowing
				depth = a_Input.projTexSpot1.z / a_Input.projTexSpot1.w;

				// Now linearise using a formula by Humus, drawn from the near and far clipping planes of the camera.
				sceneDepth = _NearClip * (depth + 1.0) / (_FarClip + _NearClip - depth * (_FarClip - _NearClip));

				// Transform to texel space
				texelpos = _TexSize * a_Input.projTexSpot1.xy;

				// Determine the lerp amounts.           
				lerps = frac(texelpos);

				// sample shadow map
				dx = 1.0f / _TexSize;
				s0 = (DecodeFloatRGBA(tex2D(_ShadowMapSpot1, a_Input.projTexSpot1.xy)) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				s1 = (DecodeFloatRGBA(tex2D(_ShadowMapSpot1, a_Input.projTexSpot1.xy + float2(dx, 0.0f))) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				s2 = (DecodeFloatRGBA(tex2D(_ShadowMapSpot1, a_Input.projTexSpot1.xy + float2(0.0f, dx))) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				s3 = (DecodeFloatRGBA(tex2D(_ShadowMapSpot1, a_Input.projTexSpot1.xy + float2(dx, dx))) + _Bias < sceneDepth) ? 0.0f : 1.0f;

				float shadowCoeffSpot1 = lerp(lerp(s0, s1, lerps.x), lerp(s2, s3, lerps.x), lerps.y);

				// Calculate vector to the camera
				float3 toCamera = normalize(_vecCameraPos.xyz - a_Input.posWorld.xyz);

				// Calculate the vector to the light (unnormalized so the length can be used to decrease
				// intensity with distance
				float3 lightUnNorm = _vecLightPos.xyz - a_Input.posWorld.xyz;

				// Calculate the ambient colour component
				_ambLightColour.rgb = _lightColour * _ambientLight;

				// Finalise the diffuse component
				float3 diffMultiplier = (a_Input.diff * _lightIntensity) / length(lightUnNorm);

				float3 toFire = (_vecFirePos - a_Input.posWorld.xyz);

				float3 fireDiff = max(0, dot(normal, normalize(toFire)));
				fireDiff *= _fireIntensity / length(toFire);

				// Calculate the vector to the first spot light
				float3 light = normalize(_vecSpotLight0Pos.xyz - a_Input.posWorld.xyz);

				// Initialise diffuse as 0 so no diffuse is applied to parts outside of the angle
				float spot0Diffuse = pow(max(dot(_vecSpotLight0Dir, -light), 0.0f), _spotLight0Angle);
				spot0Diffuse *= abs(dot(normal, -light));

				// Finalise the diffuse component for the first spot light
				float spot0Multiplier = spot0Diffuse * _lightColour * _spotLight0Intensity;

				// Calculate the vector to the second spot light
				light = normalize(_vecSpotLight1Pos.xyz - a_Input.posWorld.xyz);

				// Initialise diffuse as 0 so no diffuse is applied to parts outside of the angle
				float spot1Diffuse = pow(max(dot(_vecSpotLight1Dir, -light), 0.0f), _spotLight1Angle);
				spot1Diffuse *= abs(dot(normal, -light));

				// Finalise the diffuse component for the second spot light
				float spot1Multiplier = spot1Diffuse * _lightColour * _spotLight1Intensity;

				// Apply the colour changes
				colour.xyz *= diffMultiplier * shadowCoeff + _ambLightColour + spot0Multiplier * shadowCoeffSpot0 + spot1Multiplier * shadowCoeffSpot1 + fireDiff;

				clip(colour.a - 0.25f);

				return colour;
			}

		ENDCG
		}
	}
}
