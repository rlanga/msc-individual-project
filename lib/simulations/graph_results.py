#!/usr/bin/env python3
import matplotlib.pyplot as plt
from scipy.stats import norm
from collections import defaultdict
from re import match, compile

# Boxplot code adapted from: https://stackoverflow.com/questions/29777017/show-mean-in-the-box-plot-in-python
# PDF calculation code adapted from: http://www.learningaboutelectronics.com/Articles/How-to-create-a-probability-density-function-plot-in-Python.php

def extract_tuple_values(tup: str) -> tuple:
    stripped = tup.strip('{}\n')
    split = stripped.split(',', 1)
    elem0 = int(split[0])
    elem1 = eval(split[1])
    return (elem0, elem1)

def calculate_means(vals: list) -> list:
    result = []
    for lst in vals:
        print(f'{sum(lst)} {len(lst)}')
        result.append(sum(lst) / len(lst))
    return result

def path_length_network_size() -> None:
    with open('path_length_results.txt', 'r') as plr:
        # fig, ax = plt.subplots()
        k = []
        labels = []
        for result in plr.readlines():
            l = extract_tuple_values(result)
            labels.append(l[0])
            k.append(l[1])
        print(calculate_means(k))
        plt.boxplot(k, positions=labels, showmeans=True)
        plt.xlabel("Number of nodes (2^K)")
        plt.ylabel("Path Length")
        plt.show()


def path_length_pdf() -> None:
    with open('path_length_results.txt', 'r') as plr:
        k = None
        for line in plr.readlines():
            k = line
        k = extract_tuple_values(k)[1]
        k.sort()
        plt.plot(k, norm.pdf(k))
        plt.ylabel("PDF")
        plt.xlabel("Path length")
        plt.show()


def load_balance_network_size() -> None:
    with open('load_balance_results.txt', 'r') as lbr:
        # d = extract_tuple_values(lbr.readline())
        key_load = defaultdict(list)
        for result in lbr.readlines():
            l = extract_tuple_values(result)
            key_load[l[0]//100000].extend(l[1])
        print(calculate_means(key_load.values()))
        plt.boxplot(list(key_load.values()), positions=list(key_load.keys()), showmeans=True)
        plt.xlabel("Total number of keys (x 100,000)")
        plt.ylabel("Number of keys per node")
        plt.show()
        

def load_balance_pdf() -> None:
    with open('load_balance_results.txt', 'r') as lbr:
        keys = []
        key_match = compile(r'{500000, ')
        for line in lbr.readlines():
            if match(key_match, line):
                keys.extend(extract_tuple_values(line)[1])
        # fig = plt.figure()
        # ax = plt.gca()
        # filtered_pdf = [x if x < 0.2 else 0 for x in norm.pdf(keys)]
        # print(max(filtered_pdf))
        keys.sort()
        plt.plot(keys, norm.pdf(keys))
        # plt.yscale('log')
        # ymin, ymax = plt.ylim()
        # plt.ylim(0, 9 ** -131)

        plt.ylabel("PDF")
        plt.xlabel("Number of keys per node")
        plt.show()


if __name__ == '__main__':
    # path_length_network_size()
    path_length_pdf()
    # load_balance_network_size()
    # load_balance_pdf()

