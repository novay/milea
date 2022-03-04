class Serializer;
class Trade;

struct EADetails {
    Trade *trade;
    EADetails(Trade *_trade) {}

    void SerializeStub(int _n1 = 1, int _n2 = 1, int _n3 = 1, int _n4 = 1, int _n5 = 1) {}
    SerializerNodeType Serialize(Serializer &_s) {
        // _s.Enter(SerializerEnterObject, "ACCOUNT");
        // _s.PassObject(this, "Account", *trade.Account());
        // _s.Leave();
        return SerializerNodeObject;
    }
};