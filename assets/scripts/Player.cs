public class Player : Grindstone.SmartComponent
{
    #region Public Fields
    public float speed = 10.0f;
    #endregion

    #region Private Fields
    private EulerAngles lookEuler = new EulerAngles();
    #endregion

    #region Event Methods
    public override void OnUpdate()
    {
        Float2 halfWindowSize = new Float2(800.0f, 600.0f) / 2.0f;
        Float2 mousePos = Grindstone.Input.InputManager.MousePosition;
        Float2 lookVec = new Float2(
            (mousePos.x - halfWindowSize.x) / halfWindowSize.x,
            (mousePos.y - halfWindowSize.y) / halfWindowSize.y
        );
        Grindstone.Input.InputManager.MousePosition = halfWindowSize;
        bool w = Grindstone.Input.InputManager.IsKeyDown(Grindstone.Input.KeyboardKey.W);
        bool s = Grindstone.Input.InputManager.IsKeyDown(Grindstone.Input.KeyboardKey.S);
        bool a = Grindstone.Input.InputManager.IsKeyDown(Grindstone.Input.KeyboardKey.A);
        bool d = Grindstone.Input.InputManager.IsKeyDown(Grindstone.Input.KeyboardKey.D);
        float fwd = (w ? 1.0f : 0.0f) - (s ? 1.0f : 0.0f);
        float rgt = (d ? 1.0f : 0.0f) - (a ? 1.0f : 0.0f);
        var transf = entity.GetTransformComponent();
        Float3 movementDirection =
            transf.Forward * fwd +
            transf.Right * rgt;

        float dt = 0.02f;
        Float3 offset = movementDirection * dt * speed;

        float mouseSensitivity = 8.0f;
        lookEuler.pitch -= mouseSensitivity * lookVec.x * dt;
        lookEuler.roll += mouseSensitivity * lookVec.y * dt;
        transf.Rotation = new Quaternion(lookEuler);
        transf.Position += offset;
    }
    #endregion
}
