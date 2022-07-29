extern(C):

import n64.sm64h;

void hmain()
{
    if (controller.buttonDown & Button.A)
        drawStringFormat(40, 40, "hello", 0);
    else
        drawStringFormat(40, 80, "no A", 0);
}
