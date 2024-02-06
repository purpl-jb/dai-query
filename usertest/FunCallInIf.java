class FunCallInIf {
    static int sum(int x, int y) {
        int x1 = x;
        x = 0;
        return x1 + y;
    }
    
    public static void main(String[] args) {
        int a = 0;
        int b = 0;
        int c = 0;
        if (a > 0) {
            b = a + 5;
            c = sum(a, b);
        } else {
            a = -a;
            b = a + 1;
            c = sum(a, b);
        }
    }
}
