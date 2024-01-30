public class SimpleFuns {
    static int sum(int x, int y) {
        return x + y;
    }
    
    static int add1(int x) {
        return x + 1;
    }
    
    static int useadd1(int x) {
        return -add1(x);
    }

    public static void main(String[] args) {
        int i42 = 42;
        int sum45 = sum(i42, 3);
        int sum0 = sum(-5, 5);
        int sum90 = sum(sum45, sum45);
        int add1sum = sum(add1(0), 0);
        int i10 = useadd1(-11);
        System.out.println("SimpleFuns.main");
    }
}
