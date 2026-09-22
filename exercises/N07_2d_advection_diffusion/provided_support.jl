# 提供: N07セル中心格子と辺順。計算・保存・解析・作図で共有する。
using HDF5, SHA, TOML
const DEFAULT_OUTPUT_DIR=joinpath(@__DIR__,"results")
const OUTPUT_NAMES=("temperature.h5","burgers.h5","summary.toml","temperature_comparison.png","boundary_heat.png","burgers_fields.png","convergence.png","plots.toml")
const OFFICIAL_GRIDS=((40,30),(80,60),(160,120))
const SAVE_TIMES=[0.,.25,.5,.75,1.]
const SIDES=("west","east","south","north")
case_id(nx,ny)="n$(lpad(nx,3,'0'))x$(lpad(ny,3,'0'))"
cell_centers(n,L)=collect(((1:n).-0.5).*(L/n))
