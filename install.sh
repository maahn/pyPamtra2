#! /usr/bin/env bash 
set -e

cd pyPamtraRadarSimulator
python setup.py install
cd ../

cd pyPamtraRadarMoments
python setup.py install
cd ../

cd pamtra2
python setup.py install
cd ../

cd refractive
python setup.py install
cd ../

cd scattering
python setup.py install
cd ../
