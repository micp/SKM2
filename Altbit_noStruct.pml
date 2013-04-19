mtype {MSG, ACK};

chan sExit = [2] of {mtype, bit, byte};
chan sEnt = [2] of {mtype, bit, byte};

chan cEnt = [2] of {mtype, bit, byte};
chan cExit = [2] of {mtype, bit, byte};

proctype PairServer(chan ent, exit)
{
    bit sendbit, recvbit;
    byte data;
    byte MAX = 255;

    do
    :: exit ! MSG(sendbit, data) ->
        if
        :: ent ? ACK(recvbit) ->
           if
           :: recvbit == sendbit -> 
               sendbit = 1 - sendbit;
               data = (data+1)%MAX;
           :: else
           fi
        :: timeout
        fi
    od
}

proctype Server(chan ent, exit)
{
    bit sendbit, recvbit;
    byte data;
    byte MAX = 255;

    do
    :: exit ! MSG(sendbit) ->
        if
        :: ent ? ACK -> 
            sendbit = 1 - sendbit;
            data = (data+1)%MAX;
        :: timeout
        fi
    od
}

proctype Client(chan ent, exit)
{
    bit recvbit, recvbit_last;
    byte data, data_last;
    byte MAX = 255;

    do
    :: ent ? MSG(recvbit, data) ->
        exit ! ACK(recvbit);
        if
        :: (recvbit == recvbit_last) -> skip
        :: (recvbit != recvbit_last) ->
            assert((data_last+1)%MAX == data);
            data_last = data;
            recvbit_last = recvbit;
        fi
    od
}

proctype GoodChannel(chan ent, exit)
{
    mtype rectype;
    bit recvbit;
    byte data;

    do
    :: ent ? rectype, recvbit, data -> exit ! rectype, recvbit, data
    od
}

proctype BrokenChannel(chan ent, exit)
{
    mtype rectype, rectype_last;
    bit recvbit, recvbit_last;
    byte data, data_last;
    bit missed;

    do
    :: ent ? rectype, recvbit, data ->
        if
        :: exit ! rectype, recvbit, data;
            missed = 0;
        :: (missed == 1) -> 
            exit ! rectype_last, recvbit_last, data_last;
            exit ! rectype, recvbit, data;
            missed = 0;
        :: skip -> 
            rectype_last = rectype;
            recvbit_last = recvbit;
            data_last = data;
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
