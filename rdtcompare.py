"""Compare encoding results in terms of rate, distortion, and time

python rdtcompare.py path_to_dir keyword_of_run1 keywork_of_run_2
"""
from __future__ import print_function

import os
import sys
import glob
import numpy as np
import re
from bjontegaard_metric import *

seqs = ['bus', 'city', 'crew', 'foreman', 'harbour', 'mobile']
#seqs = ['bus', 'city']

def get_rdt(filename):
  with open(filename) as f:
    content = f.readlines()
  num_bitrate = (len(content)-1)/3
  bps = np.zeros((num_bitrate))
  bpf = np.zeros((num_bitrate))
  psnr = np.zeros((num_bitrate, 3))
  enc_time = np.zeros((num_bitrate))

  csp_seq_info = re.split(' ', content[0])
  seq_info = [float(csp_seq_info[0]), float(csp_seq_info[1]), float(csp_seq_info[2])]

  for x in range(num_bitrate):
    csp_line1 = re.split(' |b', content[1+3*x])
    csp_line2 = re.split(' ', content[2+3*x])
    bpf[x] = float(csp_line1[-2])
    bps[x] = float(csp_line2[-4])
    psnr[x] = [float(csp_line2[2]), float(csp_line2[3]), float(csp_line2[4])]
    enc_time[x] = float(csp_line2[-2])
  return bps, psnr, enc_time, bpf, seq_info

def main():
  result_path = sys.argv[1]
  run_name1 = sys.argv[2]
  run_name2 = sys.argv[3]

  files1 = [f for g in seqs for f in glob.glob(result_path+'rdt_'+run_name1+'_'+g+'.txt')]
  files2 = [f for g in seqs for f in glob.glob(result_path+'rdt_'+run_name2+'_'+g+'.txt')]

  # compute number of bitrate levels
  with open(files1[0]) as f:
    content = f.readlines()
  num_bitrate = len(content)//3

  num_rdt = len(files1)
  bps1_all = np.zeros((num_rdt, num_bitrate))
  bpf1_all = np.zeros((num_rdt, num_bitrate))
  psnr1_all = np.zeros((num_rdt, num_bitrate, 3))
  enctime1_all = np.zeros((num_rdt, num_bitrate))
  bps2_all = np.zeros((num_rdt, num_bitrate))
  bpf2_all = np.zeros((num_rdt, num_bitrate))
  psnr2_all = np.zeros((num_rdt, num_bitrate, 3))
  enctime2_all = np.zeros((num_rdt, num_bitrate))
  seq_info_all = np.zeros((num_rdt, 3))

  # Parsing data
  for r in range(num_rdt):
    bps1_all[r], psnr1_all[r], enctime1_all[r], bpf1_all[r], seq_info_all[r] = get_rdt(files1[r])
  for r in range(num_rdt):
    bps2_all[r], psnr2_all[r], enctime2_all[r], bpf2_all[r], _ = get_rdt(files2[r])

  # compute global PSNRs (average over Y, U, V)
  mse1_all = 255**2 / (10**(psnr1_all/10))
  mse2_all = 255**2 / (10**(psnr2_all/10))
  gmse1_all = (4*mse1_all[:,:,0] + mse1_all[:,:,1] + mse1_all[:,:,2]) / 6
  gmse2_all = (4*mse2_all[:,:,0] + mse2_all[:,:,1] + mse2_all[:,:,2]) / 6
  gpsnr1_all = 10 * np.log10(255**2 / gmse1_all)
  gpsnr2_all = 10 * np.log10(255**2 / gmse2_all)

  bdrate = np.zeros((num_rdt))
  enctime_ratio = np.zeros((num_rdt))
  weights_npxl = np.zeros((num_rdt))
  for i in range(num_rdt):
    weights_npxl[i] = seq_info_all[i][0] * seq_info_all[i][1]

  # BD rate
  for r in range(num_rdt):
    bdrate[r] = BD_RATE(bps1_all[r], gpsnr1_all[r], bps2_all[r], gpsnr2_all[r])
  # bpp_i = bpf_i / npxl_i
  # overall bpp = sum bpp_i * npxl_i / sum(npxl) = sum bpf_i / sum(npxl)
  bpp1_ovl = np.sum(bpf1_all, axis=0) / np.sum(weights_npxl)
  bpp2_ovl = np.sum(bpf2_all, axis=0) / np.sum(weights_npxl)
  gmse1_ovl = np.dot(weights_npxl, gmse1_all) / np.sum(weights_npxl)
  gmse2_ovl = np.dot(weights_npxl, gmse2_all) / np.sum(weights_npxl)
  gpsnr1_ovl = 10 * np.log10(255**2 / gmse1_ovl)
  gpsnr2_ovl = 10 * np.log10(255**2 / gmse2_ovl)
  bdrate_ovl = BD_RATE(bpp1_ovl, gpsnr1_ovl, bpp2_ovl, gpsnr2_ovl)

  # Time
  enctime_ratio = np.sum(enctime2_all, axis=1) / np.sum(enctime1_all, axis=1)
  enctime_ratio_ovl = np.sum(enctime2_all) / np.sum(enctime1_all)

  print('=== '+run_name2+' vs ' +run_name1+' ===')
  print('BD rate per sequence: \n  ', end='')
  for k in bdrate:
    print('%2.4f%%  ' % k, end= '')
  print('\nRuntime per sequence: \n  ', end='')
  for k in enctime_ratio:
    print('%2.4f%%  ' % (k*100), end='')

  print('\nOverall BD rate: ', end='')
  print('%2.4f%%' % bdrate_ovl)
  print('Overall encoding time: ', end='')
  print('%2.2f%%' % (enctime_ratio_ovl * 100))

if __name__ == '__main__':
  main()
