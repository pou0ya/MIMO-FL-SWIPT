# Energy-Efficient Federated Learning for IoT Networks With Massive MIMO-Enabled SWIPT

Simulation code for the paper: **"Energy-Efficient Federated Learning for IoT Networks With Massive MIMO-Enabled SWIPT"**, which has been published in IEEE Internet of Things Journal.

---

## 📄 About the Article

This paper investigates energy-efficient federated learning (FL) in multiple-input multiple-output (MIMO) edge-enabled Internet of Things (IoT) networks, where user equipments (UEs) are enabled with simultaneous wireless information and power transfer (SWIPT) capabilities. To jointly optimize communication and computation resources, a hierarchical optimization framework is proposed to minimize the total effective energy consumption per global FL round, while satisfying latency, power, frequency, power-splitting, and local accuracy constraints.

By exploiting the time-scale separation between wireless resource allocation and learning accuracy adaptation, the resulting nonconvex problem is decomposed into a short-term convexified subproblem for communication and computation resource optimization, solved via successive convex approximation (SCA), and a long-term subproblem for local accuracy updates, addressed using coordinate descent (CD). The proposed algorithm ensures convergence to a stationary solution with polynomial complexity, achieving significant computational savings compared to exhaustive search.

**Key Contributions:**
- Unified end-to-end energy consumption model for SWIPT-enabled mMIMO FL systems
- Joint communication-computation-learning optimization with latency, power, and accuracy constraints
- Two-timescale decomposition leveraging time-scale separation between wireless resource allocation and learning accuracy adaptation
- Short-term subproblem solved via SCA and long-term accuracy update via CD
- Monotonic descent and convergence to a stationary solution with polynomial-time complexity

---

## 🔧 Requirements

- **MATLAB** (R2020a or later recommended)
- **CVX** (Cvx Research, Inc.) - Required for solving the convex subproblems
  - Download from: http://cvxr.com/cvx/
  - Install and run `cvx_setup` before executing the code

---

## 🚀 Usage

### 1. Setup CVX

Ensure CVX is properly installed and initialized:

```matlab
cvx_setup
```

### 2. Run the Simulation

Simply execute the main script in MATLAB:

```matlab
main
```

---

## 📝 Citation

If you use this code for research that results in publications, please cite our original article:

```bibtex
@article{mozafari2026energy,
  title={Energy-Efficient Federated Learning for IoT Networks With Massive MIMO-Enabled SWIPT},
  author={Mozafari, Mohammad and Hosseini, Maryam and Hosseini, Pouya and Zahedi, Abdulhamid and Abouei, Jamshid and Mohammadi, Arash},
  journal={IEEE Internet of Things Journal},
  volume={13},
  number={12},
  pages={--},
  month={Jun.},
  year={2026},
  publisher={IEEE}
}
```

---

## 🤝 Contact

- Pouya Hosseini: hosseini.pouya7279@gmail.com

---
