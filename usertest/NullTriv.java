class NullTriv {
    static class Foo { }
    
    public static void main(String[] args) {
        Foo a = null;
        Foo b = new Foo();
        Foo c = new Foo();
        Foo d = b;
        d = c;
        c = null;
        if (c == null) {
            a = new Foo();
        }
    }
}
