import n64.sm64h;
extern(C):

__gshared aPresses = 0;

void hmain()
{
    if (controller.buttonPressed & Button.A)
    {
        aPresses++;
    }
    drawStringFormat(20, 190, "A" ~ STR_X ~ "%d", aPresses);
}
