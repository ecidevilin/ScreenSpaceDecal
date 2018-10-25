using UnityEngine;

[RequireComponent(typeof(Camera))]
public class ScreenSpaceDecal : MonoBehaviour
{
	Camera mCam;
    public Material DecalMaterial;
    
	void OnEnable ()
	{
		mCam = GetComponent<Camera>();
        mCam.depthTextureMode |= DepthTextureMode.Depth;
    }

	// Called by camera to apply image effect
	void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
	    if (DecalMaterial == null)
        {
            Graphics.Blit(source, destination);
            return;
        }
        DecalMaterial.SetMatrix("_InverseMVP", mCam.cullingMatrix.inverse);
        Graphics.Blit(source, destination, DecalMaterial);
	}
}