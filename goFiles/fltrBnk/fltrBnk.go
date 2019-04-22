package main

/*
#cgo CFLAGS: -g -Wall -O3 -ffast-math
#include "fltrBnk.h"
*/
import "C"

import (
	"bufio"
	"fmt"
	"gopkg.in/yaml.v2"
	"io/ioutil"
	"math"
	"math/cmplx"
	"os"
	"regexp"
	"strconv"
	"time"
	// "runtime"
)

type Config struct {
	Nmbsections string
	Sections    []map[string]string
}

var regXpr = regexp.MustCompile(`(-?[0-9]+\.[0-9]+) \+ (-?[0-9]+\.[0-9]+)i *`)

const nmbChnls = 64
const nmbInpts = 8192
var Xout [nmbInpts][nmbChnls] C.complexdouble
var Fshfts [nmbChnls] C.complexdouble

func parseCmplx(val string) (rval complex128) {
	vals := regXpr.FindStringSubmatch(val)
	if f1, err := strconv.ParseFloat(vals[1], 64); err == nil {
		f2, _ := strconv.ParseFloat(vals[2], 64)
		rval = complex(f1, f2)
	} else {
		rval = 0 + 0i
	}
	return
}

func main() {
	// var vals []string
	// var f1, f2 float64
	var A [20][4]complex128
	var B [20][2]complex128
	var C [20][2]complex128
	var D [20]complex128
	var frqShfts [nmbChnls]complex128
	var xin [nmbInpts]complex128
	var xinJ [nmbInpts][nmbChnls]complex128
	var xout [nmbInpts][nmbChnls]complex128
	var x1 [20][nmbChnls]complex128
	var x2 [20][nmbChnls]complex128
	var xi1 [20][nmbChnls]complex128
	var xi2 [20][nmbChnls]complex128

	if len(os.Args) != 2 {
		fmt.Println("Incorrect Arguments")
		return
	}

	filename := os.Args[1]

	var config Config
	source, err := ioutil.ReadFile(filename)
	if err != nil {
		panic(err)
	}
	err = yaml.Unmarshal(source, &config)
	if err != nil {
		panic(err)
	}
	n, err := strconv.Atoi(config.Nmbsections)
	// A := make([][]complex, n)
	fmt.Printf("Nmbsections: %u\n", n)
	fmt.Printf("Sections: %#+v\n", config.Sections)
	for i := 0; i < n; i++ {
		if val, ok := config.Sections[i]["a11"]; ok {
			A[i][0] = parseCmplx(val)
			val, ok = config.Sections[i]["a12"]
			A[i][1] = parseCmplx(val)
			val, ok = config.Sections[i]["a21"]
			A[i][2] = parseCmplx(val)
			val, ok = config.Sections[i]["a22"]
			A[i][3] = parseCmplx(val)
			val, ok = config.Sections[i]["b1"]
			B[i][0] = parseCmplx(val)
			val, ok = config.Sections[i]["b2"]
			B[i][1] = parseCmplx(val)
			val, ok = config.Sections[i]["c1"]
			C[i][0] = parseCmplx(val)
			val, ok = config.Sections[i]["c2"]
			C[i][1] = parseCmplx(val)
			val, ok = config.Sections[i]["d"]
			D[i] = parseCmplx(val)
		} else {
			val, ok = config.Sections[i]["a"]
			A[i][0] = parseCmplx(val)
			val, ok = config.Sections[i]["b"]
			B[i][0] = parseCmplx(val)
			val, ok = config.Sections[i]["c"]
			C[i][0] = parseCmplx(val)
			val, ok = config.Sections[i]["d"]
			D[i] = parseCmplx(val)
		}
	}

	deltaF := 1.0 / nmbChnls
	for k := 0; k < nmbChnls; k++ {
	// for k := -nmbChnls/2 + 1; k <= nmbChnls/2; k++ {
		k_ := float64(k - nmbChnls/2 + 1)
		frqShfts[k] = cmplx.Rect(1.0, deltaF*k_*2.0*math.Pi)
	}
	xin[0] = 1
	t0 := time.Now()
	for i := 0; i < nmbInpts; i++ {
		chnlMltplr := 1.0 + 0.0i
		for k := 0; k < nmbChnls; k++ {
			// runtime.Breakpoint()
			chnlMltplr = chnlMltplr*(1.0i)
			xinJ[i][k] = chnlMltplr*xin[i]
		}
		for j := 0; j < n; j++ {
			if _, ok := config.Sections[j]["a11"]; ok {
				for k := 0; k < nmbChnls; k++ {
					xout[i][k] = C[j][0]*x1[j][k] + C[j][1]*x2[j][k] + D[j]*xinJ[i][k]
					/*
					fmt.Printf("i: %d, T1: %12.4e, T2: %12.4e, T3: %12.4e\n", i, C[j][0]*x1[j][k], C[j][1]*x2[j][k], D[j]*xinJ[i][k])
					fmt.Printf("\txinJ: %12.4e, xout: %12.4e\n", xinJ[i][k], xout[i][k])
					fmt.Printf("\tC[j][0]: %12.4e, x1[j][k]: %12.4e\n", C[j][0], x1[j][k])
					*/
					xi1[j][k] = A[j][0]*x1[j][k] + A[j][1]*x2[j][k] + B[j][0]*xinJ[i][k]
					xi2[j][k] = A[j][2]*x1[j][k] + A[j][3]*x2[j][k] + B[j][1]*xinJ[i][k]
					x1[j][k] = xi1[j][k] * frqShfts[k]
					x2[j][k] = xi2[j][k] * frqShfts[k]
				}
			} else {
				for k := 0; k < nmbChnls; k++ {
					xout[i][k] = C[j][0]*x1[j][k] + D[j]*xinJ[i][k]
					xi1[j][k] = A[j][0]*x1[j][k] + B[j][0]*xinJ[i][k]
					x1[j][k] = xi1[j][k] * frqShfts[k]
				}
			}
			for k := 0; k < nmbChnls; k++ {
				xinJ[i][k] = xout[i][k]
				// fmt.Printf("\txinJ: %12.4e, xout: %12.4e\n", xinJ[i][k], xout[i][k])
			}
		}
	}
	t1 := time.Now()
	fmt.Printf("\nSimulation time for Go: %5.2vms\n", t1.Sub(t0))
	// fmt.Printf("Number of CPUs: %v\n", runtime.NumCPU())

	f, err := os.Create("fltr.dat")
	w := bufio.NewWriter(f)
	// check(err)
	defer f.Close()
	// runtime.Breakpoint()
	for i := 0; i < nmbInpts; i++ {
		for k := 0; k < nmbChnls; k++ {
			fmt.Fprintf(w, "%11.5e ", xout[i][k])
		}
		w.WriteString("\n")
		w.Flush()
		// fmt.Fprintf(w, "\n")
	}
	// fmt.Printf("wrote %d bytes\n", n3)
	// w.WriteString("\n")
	w.Flush()
	f.Sync()

	type Csctn C.struct_sctn
	// type Ccoeffs C.struct_fltCoeffs
	var cCoeffs C.struct_fltCoeffs

	// var Csctns [20] Csctn
	cCoeffs.nmbSctns = C.int(n)

	for i := 0; i < n; i++ {
		sctn := C.struct_sctn {
			a11: _Ctype_complexdouble(A[i][0]),
			a12: C.complexdouble(A[i][1]),
			a21: C.complexdouble(A[i][2]),
			a22: C.complexdouble(A[i][3]),
			b1: C.complexdouble(B[i][0]),
			b2: C.complexdouble(B[i][1]),
			c1: C.complexdouble(C[i][0]),
			c2: C.complexdouble(C[i][1]),
			d: C.complexdouble(D[i]),
		}
		if _, ok := config.Sections[i]["a11"]; ok {
			sctn.order = 2
		} else {
			sctn.order = 1
		}
		cCoeffs.sctns[i] = sctn
	}
	for k := 0; k < nmbChnls; k++ {
		Fshfts[k] = C.complexdouble(frqShfts[k])
	}

	C.cFltr( &cCoeffs, C.int(nmbInpts), C.int(nmbChnls), &Fshfts[0] )
	fmt.Println("Finished")
}
