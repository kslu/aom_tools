"""Compare instruction counts and run time

python speedcompare.py path_to_dir keyword_of_run1 keywork_of_run_2
"""
from __future__ import print_function

import os
import sys
import glob
import numpy as np
import re
from bjontegaard_metric import *


def get_speed(filename):
  with open(filename) as f:
    content = f.readlines()
  num_speed = len(content) / 3
  speeds = np.zeros((num_speed))
  instrucs = np.zeros((num_speed))
  rts = np.zeros((num_speed))

  for x in range(num_speed):
    sp_line = re.split(' ', content[3 * x])
    ins_line = re.split(' ', content[1 + 3 * x])
    rt_line = re.split(' ', content[2 + 3 * x])
    speeds[x] = int(sp_line[1])
    instrucs[x] = int(ins_line[0].replace(',', ''))
    rts[x] = float(rt_line[0])
  return speeds, instrucs, rts


def main():
  result_path = sys.argv[1]
  run_name1 = sys.argv[2]
  run_name2 = sys.argv[3]

  spfile1 = os.path.join(result_path, 'speed_' + run_name1 + '.txt')
  spfile2 = os.path.join(result_path, 'speed_' + run_name2 + '.txt')

  sps1, instrucs1, rts1 = get_speed(spfile1)
  sps2, instrucs2, rts2 = get_speed(spfile2)

  assert all(sps1 == sps2)

  instruc_speedup = (instrucs1.astype(float) -
                     instrucs2.astype(float)) / instrucs1.astype(float) * 100
  rt_speedup = (rts1 - rts2) / rts1 * 100

  print('=== ' + run_name2 + ' vs ' + run_name1 + ' ===')
  for k in range(len(sps1)):
    print('--- Speed %d ---' % sps1[k])
    print('Instruction count speedup: %.3f%%' % instruc_speedup[k])
    print('Runtime speedup: %.3f%%' % rt_speedup[k])


if __name__ == '__main__':
  main()
