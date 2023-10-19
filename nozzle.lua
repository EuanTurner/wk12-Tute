-- 2023-10-17
-- Author: Euan Turner, 44820949

nozContFile = "nozzle-contour.dat"
config.title = "Supersonic Nozzle"
config.dimensions = 2
config.axisymmetric = true 

-- set gas conditions
setGasModel('ideal-air.gas')
p_res = 500.0 --Pa
T_res = 300.0 --K
initial = FlowState:new{p=p_res, T=T_res}
exp_region = FlowState:new{p=0.1*p_res, T=T_res}

-- Geometry
nozContour = Spline2:new{filename=nozContFile}
nozReparam = ArcLengthParameterizedPath:new{underlying_path=nozContour}
A = nozContour(0.0)
B = nozContour(1.0)
D = {x=A.x, y=0.0}
C = {x=B.x, y=0.0}

--Build single patch over the region
patch = CoonsPatch:new{north=nozContour,
                        east=Line:new{p0=C, p1=B},
                        south=Line:new{p0=D, p1=C},
                        west=Line:new{p0=D, p1=A}
}

--build single grid over region
nxcells = 100
nycells = 20
grid = StructuredGrid:new{psurface=patch, niv=nxcells+1, njv=nycells+1}

--split the fill conditions
xMid = nozContour(0.5).x
function fillCondition(x, y, z)
    if x < xMid then return initial end 
    return exp_region
end 

blk = FluidBlock:new{grid=grid, initialState = fillCondition,
                    bcList = {west=InFlowBC_FromStagnation:new{stagnationState=initial},
                                east=OutFlowBC_Simple:new{}}}

config.max_time = 10.0e-3
config.max_step = 50000
config.dt_init = 1.0e-6
config.cfl_value = 0.7
config.dt_plot = config.max_time/50
config.dt_history = 1.0e-5

config.flux_calculator = "ausmdv"

-- Two history points at inflow and exit
setHistoryPoint{x=A.x, y=A.y}
setHistoryPoint{x=B.x, y=B.y}


