mtype {MSG, ACK};

typedef Struct {
    mtype type;
    bit bb;
    int ii;
}

chan servout = [1] of {Struct};
chan servin = [1] of {Struct};

proctype serv(chan cin, cout)
{
    Struct sin;

    cout ! MSG(3, 3) ->
        cin ? ACK(sin);
        assert(sin.type == ACK);
        assert(sin.bb == 1);
        assert(sin.ii == 3);
}

proctype cli(chan cin, cout)
{
    Struct sin;

    cin ? sin ->
        cout ! ACK(sin.bb, sin.ii);
}

init
{
    run serv(servin, servout);
    run cli(servout, servin);
}
