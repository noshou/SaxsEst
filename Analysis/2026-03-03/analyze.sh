# created this script bc I did the analysis *before* writing CleanAndPlot.R
# to run this script, place it in the project root. script is 100% POSIX compliant,
# so you can run on any script, so no need for shebang :)

for dir in \
  'epsilon=0.395-sample_size=10%' 'epsilon=0.395-sample_size=15%' 'epsilon=0.395-sample_size=20%' \
  'epsilon=0.395-sample_size=25%' 'epsilon=0.395-sample_size=30%' 'epsilon=0.395-sample_size=35%' \
  'epsilon=0.395-sample_size=40%' 'epsilon=0.395-sample_size=45%' 'epsilon=0.395-sample_size=5%' \
  'epsilon=0.395-sample_size=50%' 'epsilon=0.39-sample_size=10%' 'epsilon=0.39-sample_size=15%' \
  'epsilon=0.39-sample_size=20%' 'epsilon=0.39-sample_size=25%' 'epsilon=0.39-sample_size=30%' \
  'epsilon=0.39-sample_size=35%' 'epsilon=0.39-sample_size=40%' 'epsilon=0.39-sample_size=45%' \
  'epsilon=0.39-sample_size=5%' 'epsilon=0.39-sample_size=50%' 'epsilon=0.405-sample_size=10%' \
  'epsilon=0.405-sample_size=15%' 'epsilon=0.405-sample_size=20%' 'epsilon=0.405-sample_size=25%' \
  'epsilon=0.405-sample_size=30%' 'epsilon=0.405-sample_size=35%' 'epsilon=0.405-sample_size=40%' \
  'epsilon=0.405-sample_size=45%' 'epsilon=0.405-sample_size=5%' 'epsilon=0.405-sample_size=50%' \
  'epsilon=0.40-sample_size=10%' 'epsilon=0.40-sample_size=15%' 'epsilon=0.40-sample_size=20%' \
  'epsilon=0.40-sample_size=25%' 'epsilon=0.40-sample_size=30%' 'epsilon=0.40-sample_size=35%' \
  'epsilon=0.40-sample_size=40%' 'epsilon=0.40-sample_size=45%' 'epsilon=0.40-sample_size=5%' \
  'epsilon=0.40-sample_size=50%' 'epsilon=0.4105-sample_size=10%' 'epsilon=0.4105-sample_size=15%' \
  'epsilon=0.4105-sample_size=20%' 'epsilon=0.4105-sample_size=25%' 'epsilon=0.4105-sample_size=30%' \
  'epsilon=0.4105-sample_size=35%' 'epsilon=0.4105-sample_size=40%' 'epsilon=0.4105-sample_size=45%' \
  'epsilon=0.4105-sample_size=5%' 'epsilon=0.4105-sample_size=50%' 'epsilon=0.41-sample_size=10%' \
  'epsilon=0.41-sample_size=15%' 'epsilon=0.41-sample_size=20%' 'epsilon=0.41-sample_size=25%' \
  'epsilon=0.41-sample_size=30%' 'epsilon=0.41-sample_size=35%' 'epsilon=0.41-sample_size=40%' \
  'epsilon=0.41-sample_size=45%' 'epsilon=0.41-sample_size=5%' 'epsilon=0.41-sample_size=50%' \
  'epsilon=0.4205-sample_size=10%' 'epsilon=0.4205-sample_size=15%' 'epsilon=0.4205-sample_size=20%' \
  'epsilon=0.4205-sample_size=25%' 'epsilon=0.4205-sample_size=30%' 'epsilon=0.4205-sample_size=35%' \
  'epsilon=0.4205-sample_size=40%' 'epsilon=0.4205-sample_size=45%' 'epsilon=0.4205-sample_size=5%' \
  'epsilon=0.4205-sample_size=50%' 'epsilon=0.42-sample_size=10%' 'epsilon=0.42-sample_size=15%' \
  'epsilon=0.42-sample_size=20%' 'epsilon=0.42-sample_size=25%' 'epsilon=0.42-sample_size=30%' \
  'epsilon=0.42-sample_size=35%' 'epsilon=0.42-sample_size=40%' 'epsilon=0.42-sample_size=45%' \
  'epsilon=0.42-sample_size=5%' 'epsilon=0.42-sample_size=50%' 'epsilon=0.4305-sample_size=10%' \
  'epsilon=0.4305-sample_size=15%' 'epsilon=0.4305-sample_size=20%' 'epsilon=0.4305-sample_size=25%' \
  'epsilon=0.4305-sample_size=30%' 'epsilon=0.4305-sample_size=35%' 'epsilon=0.4305-sample_size=40%' \
  'epsilon=0.4305-sample_size=45%' 'epsilon=0.4305-sample_size=5%' 'epsilon=0.4305-sample_size=50%' \
  'epsilon=0.43-sample_size=10%' 'epsilon=0.43-sample_size=15%' 'epsilon=0.43-sample_size=20%' \
  'epsilon=0.43-sample_size=25%' 'epsilon=0.43-sample_size=30%' 'epsilon=0.43-sample_size=35%' \
  'epsilon=0.43-sample_size=40%' 'epsilon=0.43-sample_size=45%' 'epsilon=0.43-sample_size=5%' \
  'epsilon=0.43-sample_size=50%' 'epsilon=0.4405-sample_size=10%' 'epsilon=0.4405-sample_size=15%' \
  'epsilon=0.4405-sample_size=20%' 'epsilon=0.4405-sample_size=25%' 'epsilon=0.4405-sample_size=30%' \
  'epsilon=0.4405-sample_size=35%' 'epsilon=0.4405-sample_size=40%' 'epsilon=0.4405-sample_size=45%' \
  'epsilon=0.4405-sample_size=5%' 'epsilon=0.4405-sample_size=50%' 'epsilon=0.44-sample_size=10%' \
  'epsilon=0.44-sample_size=15%' 'epsilon=0.44-sample_size=20%' 'epsilon=0.44-sample_size=25%' \
  'epsilon=0.44-sample_size=30%' 'epsilon=0.44-sample_size=35%' 'epsilon=0.44-sample_size=40%' \
  'epsilon=0.44-sample_size=45%' 'epsilon=0.44-sample_size=5%' 'epsilon=0.44-sample_size=50%' \
  'epsilon=0.45-sample_size=10%' 'epsilon=0.45-sample_size=15%' 'epsilon=0.45-sample_size=20%' \
  'epsilon=0.45-sample_size=25%' 'epsilon=0.45-sample_size=30%' 'epsilon=0.45-sample_size=35%' \
  'epsilon=0.45-sample_size=40%' 'epsilon=0.45-sample_size=45%' 'epsilon=0.45-sample_size=5%' \
  'epsilon=0.45-sample_size=50%'; do
  eps=$(echo "$dir" | sed 's/epsilon=\([^-]*\)-.*/\1/')
  ss=$(echo "$dir" | sed 's/.*sample_size=\(.*\)/\1/')
  Rscript SaxsEst/CleanAndPlot.R "Analysis/2026-03-03/$dir" "$eps" "$ss"
done