class FunCallInIf {
    static int sum(int x, int y) {
        int x1 = x;
        x = 0;
        return x1 + y;
    }
    
    static int foo(int x, int y) {
        if (x > 10) {
            return sum(x, y);
        } else {
            return sum(x, -y);
        }
    }
    
    
    
    public static void main(String[] args) {
        // NOTE: for building a callgraph,
        // __nondet() should be replaced with a literal 
        
        int a = __nondet();
        int b = __nondet();
        int c = 0;
        if (a > 0) {
            if (b > 0) {
                c = foo(a, b);
            } else {
                c = foo(-a, b);
            }
            b = 5;
        } else {
            if (b > 0) {
                c = foo(b, a);
            } else {
                c = foo(b, -a);
            }
            b = -5;
        }
        int d = sum(__nondet(), 1);
    }
}
