using Grindstone.Math;
using System;

public class Player : Grindstone.SmartComponent
{
    #region Public Fields
    public float speed = 10.0f;
    #endregion

    #region Private Fields
    private EulerAngles lookEuler = new EulerAngles(0.0f, 0.0f, 0.0f);
    private bool isFirstFrame = true;
    #endregion

    #region Event Methods
    public override void OnUpdate() {
        bool isWindowFocused = Grindstone.Input.InputManager.IsWindowFocused;
        Grindstone.Input.InputManager.IsCursorVisible = !isWindowFocused;
        if (!isWindowFocused)
        {
            return;
        }

        Grindstone.Window window = Grindstone.Window.Current;
        if (Grindstone.Input.InputManager.IsKeyDown(Grindstone.Input.KeyboardKey.Escape))
        {
            window.Close();
        }

        Float2 halfWindowSize = window.Size / 2.0f;
        if (isFirstFrame) {
            Grindstone.Input.InputManager.MousePosition = halfWindowSize;
            isFirstFrame = false;
            return;
        }

        Float2 mousePos = Grindstone.Input.InputManager.MousePosition;
        Float2 lookVec = new Float2(
            (halfWindowSize.x - mousePos.x) / halfWindowSize.x,
            (halfWindowSize.y - mousePos.y) / halfWindowSize.y
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

        float dt = (float)Grindstone.Time.GetDeltaTime();
        Float3 offset = movementDirection * dt * speed;

        float mouseSensitivity = 20.0f;
        lookEuler.pitch += mouseSensitivity * lookVec.x * dt;
        lookEuler.roll += mouseSensitivity * lookVec.y * dt;

        const float maxViewAngle = (float)Math.PI * 0.45f;

        if (lookEuler.roll > maxViewAngle)
        {
            lookEuler.roll = maxViewAngle;
        }

        if (lookEuler.roll < -maxViewAngle)
        {
            lookEuler.roll = -maxViewAngle;
        }

        transf.Rotation = new Quaternion(lookEuler);
        transf.Position += offset;
    }
    #endregion
}
