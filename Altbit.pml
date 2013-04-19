mtype {MSG, ACK};

typedef Msg {
    mtype msgType;
    bit altBit;
    byte data;
}

byte MAX = 255;

chan sExit = [2] of {Msg};
chan sEnt = [2] of {Msg};

chan cEnt = [2] of {Msg};
chan cExit = [2] of {Msg};

inline copyMsg(src, dest)
{
    dest.msgType = src.msgType;
    dest.altBit = src.altBit;
    dest.data = src.data;
}

inline genData(toGen)
{
    toGen = (toGen+1)%MAX;
}

inline testData(toTest, toTestPrev)
{
    assert((toTestPrev+1)%MAX == toTest)
}

proctype PairServer(chan ent, exit)
{
    Msg msgIn, msgOut;

    do
    :: exit ! MSG(msgOut.altBit, msgOut.data) ->
        if
        :: ent ? ACK(msgIn.altBit) ->
           if
           :: msgIn.altBit == msgOut.altBit -> 
               msgOut.altBit = 1 - msgOut.altBit;
               genData(msgOut.data);
           :: else
           fi
        :: timeout
        fi
    od
}

proctype Server(chan ent, exit)
{
    Msg msgin, msgOut;

    do
    :: exit ! MSG(msgOut.altBit, msgOut.data) ->
        if
        :: ent ? ACK -> 
            msgOut.altBit = 1 - msgOut.altBit;
            genData(msgOut.data);
        :: timeout
        fi
    od
}

proctype Client(chan ent, exit)
{
    Msg recv, recvLast;

    do
    :: ent ? MSG(recv.altBit, recv.data) ->
        exit ! ACK(recv.altBit);
        if
        :: (recv.altBit == recvLast.altBit) -> skip
        :: (recv.altBit != recvLast.altBit) ->
            testData(recv.data, recvLast.data);
            copyMsg(recv, recvLast);
        fi
    od
}

proctype Channel(chan ent, exit)
{
    Msg recv;

    do
    :: ent ? recv -> exit ! recv;
    od
}

proctype BrokenChannel(chan ent, exit)
{
    Msg recv, recvLast;
    bit missed;

    do
    :: ent ? recv ->
        if
        :: exit ! recv;
            missed = 0;
        :: (missed == 1) -> 
            exit ! recvLast;
            exit ! recv;
            missed = 0;
        :: skip -> 
            copyMsg(recv, recvLast);
            missed = 1;
        :: skip
        fi
    od
}

init
{
    run PairServer(sEnt, sExit);
    run Client(cEnt, cExit);
    run BrokenChannel(sExit, cEnt);
    run BrokenChannel(cExit, sEnt);
}
