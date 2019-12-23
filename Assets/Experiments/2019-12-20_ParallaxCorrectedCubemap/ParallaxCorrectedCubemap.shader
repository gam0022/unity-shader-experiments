Shader "Unlit/ParallaxCorrectedCubemap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle] _PARALLAX_CORRECTED_CUBEMAP("Parallax-Corrected Cubemap", Float) = 1
        _ReflectRate ("Reflect Rate", Range(0, 1)) = 0.3
    }
    SubShader
    {
        Tags{
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
            "LightMode" = "ForwardBase"
            "IgnoreProjector" = "True"
        }
        Pass
        {
            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile __ _PARALLAX_CORRECTED_CUBEMAP_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _ReflectRate;

            // Parallax-Corrected Cubemap
            // https://seblagarde.files.wordpress.com/2012/08/parallax_corrected_cubemap-siggraph2012.pdf
            float3 calcParallaxCorrectedCubemapReflect(float3 worldPos, float3 worldReflect, float3 cubemapPos, float3 boxMin, float3 boxMax)
            {
                // AABB と 反射ベクトル の交差点 worldIntersectPos を計算します
                float3 firstPlaneIntersect  = (boxMax - worldPos) / worldReflect;
                float3 secondPlaneIntersect = (boxMin - worldPos) / worldReflect;
                float3 furthestPlane = max(firstPlaneIntersect, secondPlaneIntersect);
                float dist = min(min(furthestPlane.x, furthestPlane.y), furthestPlane.z);
                float3 worldIntersectPos = worldPos + worldReflect * dist;

                // Cubemapから交差点に向かうベクトルが ParallaxCorrected された反射ベクトルになります
                return worldIntersectPos - cubemapPos;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv2 = v.uv2 * unity_LightmapST.xy + unity_LightmapST.zw;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = worldPos;
                o.worldNormal = worldNormal;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                // Lightmap
                half4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv2);
                half3 lmap = DecodeLightmap(lmtex);
                col.rgb *= lmap.rgb;

                // Cubemap
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 worldReflect = reflect(-worldViewDir, i.worldNormal);

                #if _PARALLAX_CORRECTED_CUBEMAP_ON
                {
                    worldReflect = calcParallaxCorrectedCubemapReflect(i.worldPos, worldReflect, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
                }
                #endif

                half4 refColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, worldReflect, 0);
                refColor.rgb = DecodeHDR(refColor, unity_SpecCube0_HDR);
                col.rgb = lerp(col.rgb, refColor.rgb, _ReflectRate);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
