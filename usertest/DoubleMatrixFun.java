class DoubleMatrixFun {
    // copied from https://github.com/mikhailazaryan/numprog-tum/blob/main/Gauss.java
    /*static double[] backSubst(double[][] matrix, double[] b) {
        int n = matrix.length - 1;
        double[] solution = new double[n+1];

        solution[n] = b[n]/matrix[n][n];
        double dividend;
        for (int i = n-1; i >= 0; i--) {
            dividend = b[i];
            for (int j = n; j >= i+1; j--) {
                dividend -= matrix[i][j]*solution[j];
            }
            solution[i] = dividend/matrix[i][i];
        }
        return solution;
    }*/
    
    static double inc(double val) {
        return val + 1;
    }
    
    /*static double[] incAll(double[] vec) {
        double[] res = new double[vec.length];
        for (int i = 0; i < res.length; i++) {
            res[i] = vec[i] + 1.0;
        }
        return res;
    }*/
    
    static void incAllInPlace(double[] vec) {
        for (int i = 0; i < vec.length; i++) {
            vec[i] += 1.0;
        }
    }

    public static void main(String[] args) {
         double[] v = {1.0, 0.0};
         v[1] = 42;
         incAllInPlace(v);
  
        double v0 = v[0];
        double v0_inc = inc(v0);
         
        //double[] v_copy = new double[v.length];
        //double[] w = incAll(v);

        /*double[][] m = { {1.0, -2.5}, {3.75, 42.0} };
        int n_outer = m.length;
        double[] substRes = backSubst(m, v);*/
    }
}
