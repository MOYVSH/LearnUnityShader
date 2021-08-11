﻿Shader "Unlit/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "RenderType"="TransparentCutout"}

        Pass
        {
            ZWrite On
            ZTest On
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // GPU Instancing
            #pragma multi_compile_instancing
            // 表示每次实例渲染的时候，都会执行以下setup这个函数
            // #pragma instancing_options procedural:setup
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS     : NORMAL;

            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 worldNormal    : TEXCOORD1;
                float4 worldPosition   : TEXCOORD2;
            };

            struct GrassInfo{
                float4x4 localToTerrian;
                float4 texParams;
            };
            StructuredBuffer<GrassInfo> _GrassInfoBuffer;


            float2 _GrassQuadSize;
            float4x4 _TerrianLocalToWorld;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Cutoff;

            v2f vert (appdata input, uint instanceID : SV_InstanceID)
            {
                v2f output;
                float2 uv = input.uv;
                float4 positionOS = input.vertex;
                float3 normalOS = input.normalOS;
                // positionOS.xy = positionOS.xy * _GrassQuadSize;


                GrassInfo grassInfo = _GrassInfoBuffer[instanceID];

                // //将顶点和法线从Quad本地空间变换到Terrian本地空间
                // positionOS = mul(grassInfo.localToTerrian,float4(positionOS,1)).xyz;
                // normalOS = mul(grassInfo.localToTerrian,float4(normalOS,0)).xyz;

                //UV偏移缩放
                uv = uv * grassInfo.texParams.xy + grassInfo.texParams.zw;

                //从Terrian本地坐标转换到世界坐标
                float4 positionWS = mul(grassInfo.localToTerrian,positionOS);
                positionWS /= positionWS.w;

                //输出到片段着色器
                output.uv = uv;
                // output.worldPosition = positionWS;
                // output.worldNormal = mul(unity_ObjectToWorld, float4(normalOS, 0.0 )).xyz;
                output.vertex = mul(UNITY_MATRIX_VP,positionWS);
                return output;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                clip (col.a-_Cutoff);
                return col;
            }
            ENDCG
        }
    }
}
