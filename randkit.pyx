# -*- python -*-
#cython: cdivision=False

cimport cython

cdef extern from "randomkit.h":

    ctypedef struct rk_state:
        unsigned long key[624]
        int pos
        int has_gauss
        double gauss

    ctypedef enum rk_error:
        RK_NOERR = 0
        RK_ENODEV = 1
        RK_ERR_MAX = 2

    rk_error rk_randomseed(rk_state *state)
    unsigned long rk_random(rk_state *state)
    double rk_double(rk_state *state)

cdef class Uniform:
    cdef rk_state internal_state
    cdef double loc
    cdef double scale

    def __init__(self, double loc=0, double scale=1):
        cdef rk_error errcode = rk_randomseed(cython.address(self.internal_state))
        self.loc = loc
        self.scale = scale

    cdef double get(self):
        return self.loc + self.scale * rk_double(cython.address(self.internal_state))

    def __call__(self):
        return self.get()       

# -- Example usage --

import time
import numpy as np

d = 6
cdef unsigned int N = 10**d
u = Uniform()

cdef int i

print 'Experiment: taking 1e%d samples\n' % d

print "Taking single samples in a for loop:"
tic = time.time()
for i in range(N):
    np.random.uniform()
t0 = time.time() - tic
print 'numpy: %.2f' % t0

tic = time.time()
for i in range(N):
     u()
t1 = time.time() - tic
print 'randkit: %.2f (speedup %.2f)\n' % (t1, t0/t1)

print "Taking all samples in a single call:"
tic = time.time()
np.random.uniform(size=N)
t0 = time.time() - tic
print 'numpy with internal loop: %.2f' % t0


cdef class ExampleSampler(Uniform):
    cdef unsigned int N

    def __init__(self, N):
        self.N = N

    def take(self):
        cdef unsigned int i
        for i in range(self.N):
            self.get()

e = ExampleSampler(N)
tic = time.time()
e.take()
t1 = time.time() - tic
print 'randkit with internal loop: %.2f (speedup %.2f)' % (t1, t0/t1)
