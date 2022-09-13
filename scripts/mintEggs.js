const { ethers } = require("hardhat")
require("dotenv").config()

const ADDRESS_ZERO = '0x0000000000000000000000000000000000000000';
const affectedIds = [91,1443,907,837,2131,2134,1419,1421,1363,1366,717,1201,2252,126,116,560,810,853,1266,259,308,342,380,419,2618,679,338,166,220,192,129,53,71,106,150,171,2392,2391,1668,1667,1665,2320,2321,2322,2324,1824,1976,258,2595,2330,576,532,609,686,1066,2247,362,1064,1682,1685,979,905,81,929,950,794,1664,955,931,758,740,1104,496,140,1030,1071,1245,1566,1568,1817,1816,1760,1759,1757,1272,2078,2468,509,508,2496,1306,1357,2063,522,85,149,355,814,1237,110,1142,113,848,924,512,481,621,450,462,701,2241,2242,2244,619,2243,1670,2606,2607,339,464,2145,1712,1320,591,545,571,527,575,1724,2093,492,437,529,573,599,630,2173,1798,1271,1288,1834,1835,1836,1354,1647,1796,1803,505,1736,1735,191,1385,1345,484,597,627,658,696,279,330,375,937,998,386,395,444,1191,584,749,1015,1087,1440,2130,2129,1323,1318,197,242,300,315,1370,429,817,863,909,2601,2068,96,498,1474,1476,2489,1828,1827,1632,1459,1343,673,2575,908,828,1178,163,245,314,398,435,1454,1350,2125,2124,1374,1377,1842,1840,1839,1235,2172,2171,1217,1213,871,919,1361,1280,1295,1338,2184,2185,603,2493,264,377,1159,1642,1115,1239,217,2469,2072,177,212,275,337,507,224,410,514,568,610,2637,2376,1457,1905,777,557,942,1275,105,2227,2228,2488,2487,2486,1055,1061,1082,1096,1108,829,748,713,2186,2043,2018,997,884,732,716,689,2075,133,731,1730,486,499,2008,2009,1996,1997,1242,538,593,1301,1788,2408,2613,290,344,378,422,441,2073,2572,2545,1121,1137,1153,2638,17,5,1605,2168,1211,2544,644,511,473,2123,2111,2122,2121,138,2110,2108,2109,2107,145,345,2641,2254,2253,1413,1407,1241,146,934,981,1355,1359,10,1287,376,1002,1067,2600,2390,2384,1054,1060,1444,2039,1428,1424,1475,1310,1825,1518,1519,2156,2639,2640,69,1686,1687,1376,2644,965,820,797,600,530,412,2385,2383,2381,2236,2387,111,743,885,1005,2287,550,620,678,985,1010,1042,1058,243,585,1379,2583,1734,1733,1146,1135,1127,2127,2128,1418,1395,74,210,1586,1581,1804,2492,162,2375,1541,2374,2645,1255,1466,2201,2238,2382,2226,2388,1259,1265,100,835,1389,1983,815,868,2647,2648,2113,2114,2116,2117,2166,676,2159,1183,1249,1743,351,363,392,409,430,128,1653,1136,2155,926,2154,2119,2120,2118,941,874,761,766,734,1584,263,544,583,682,747,786,1481,2490,2373,1542,134,371,478,617,1029,125,1173,1558,1725,655,788,1068,1194,1262,1575,1119,14,411,488,1034,1180,2158,1783,288,727,2651,2652,2653,718,1101,1094,757,2312,2313,1286,893,962,2132,2133,2494,381,614,1503,1579,2476,2477,595,622,700,643,562,2642,2643,592,1826,1281,1252,1298,1319,1134,1145,2409,1337,2500,2499,2498,2497,1309,1110,1808,1303,1550,1551,1552,1554,1966,1965,2594,2597,2598,2654,1414,947,973,1556,1555,2656,502,1362,1823,2646,2022,1995,1793,1795,2657,2599,1302,1044,2577,2578,1722,2472,534,2423,1375,1737,1585,235,266,320,428,2424,2218,2219,543,876,1261,1766,802,825,2224,120,252,326,347,774,205,637,756,992,2632,928,1913,1915,1916,1527,1260,974,951,2096,367,526,322,712,859,2353,2354,2355,2356,2357,1398,2649,2569,2571,2570,2568,2567,1009,1037,1567,500,790,2365,2364,2362,2361,2360,1767,200,474,875,972,1931,2609,2566,2565,1872,2564,1871,445,1455,1456,1587,1588,1589,187,687,710,1445,1509,2298,2659,2126,2660,1426,2359,2358,1870,1868,1863,1864,970,1412,525,953,990,184,1429,1351,1321,1316,143,204,260,310,385,1669,1531,1528,1506,1813,206,690,1999,2350,2351,55,211,272,334,394,183,546,881,1460,1144,612,635,651,789,1843,1439,1590,878,16,958,2020,2541,819,1754,2419,2420,2536,2292,2137,1969,1956,1713,2658,2661,638,97,2065,76,238,722,959,271,1465,1497,633,2,1400,1405,1463,1467,1507,1867,1865,1845,1844,193,1877,2174,976,920,952,2410,2596,1380,1371,1365,1360,1356,980,967,921,899,877,2222,760,867,1891,1858,773,698,652,572,489,2223,809,861,295,1140,2655,448,1346,1342,1019,895,733,83,667,1514,1614,1873,1079,1114,2176,2198,1620,1621,1622,1623,1624,1859,552,1946,1944,2003,1188,558,634,694,714,121,453,1458,2157,2667,199,2090,130,248,1738,1168,1979,2140,2139,2138,2136,2135,390,423,577,613,939,1846,1847,2589,1290,1832,1833,2668,185,1312,1155,2286,2633,1764,1763,1172,1167,963,1787,1786,1785,1784,1782,1904,1906,1949,1950,2466,102,2669,1886,1885,1884,1883,1881,1138,169,602,2089,452,457,471,480,487,2671,2579,2580,2626,2582,2197,519,841,127,889,1779,1778,1777,1776,1775,67,141,262,360,403,439,2352,348,2471,993,961,580,564,323,675,831,1011,1438,1880,1879,1869,1674,1673,913,969,2673,2674,359,1512,1791,1352,1313,642,528,466,1139,1274,503,535,1882,2221,1748,1878,1221,1774,1773,1772,1771,1770,778,791,796,1031,1036,628,1637,1048,2675,2672,1671,1661,1658,1656,1655,268,495,173,1769,1626,1625,956,1675,1855,2470,2475,589,296,1651,1603,1595,1591,1583,1594,1001,1781,1580,1576,1571,1569,1511,596,2460,179,590,911,1907,1909,851,1633,1727,2170,416,112,440,151,207,246,475,839,1800,1893,898,925,1392,208,2539,1876,1875,1874,648,408,436,455,555,2151,2676,60,2083,161,517,2349,787,331,267,418,447,540,397,2002,2291,2677,692,2010,2683,2678,2679,2680,2681,2682,2684,1111,1282,95,1641,1192,944,1025,625,72,195,515,569,1124,736,2612,2437,1150,768,1147,2685,2411,1768,406,482,1570,1929,688,1397,154,2190,2191,2192,2193,2194,250,189,313,265,285,2195,1441,52,738,2205,1378,2689,1423,1399,329,349,364,382,393,2019,2017,2686,407,414,433,451,459,2395,1643,1677,1679,2377,2378,2178,2179,1662,904,2397,108,684,549,491,483,470,2396,425,711,770,2608,1698,1700,1694,1692,1696,370,63,118,164,190,230,165,606,401,413,579,618,650,307,923,946,1049,1069,1689,1690,1691,353,1887,1888,574,286,432,647,2693,2694,356,1918,1920,1921,1922,1923,2691,2692,1336,1100,1056,721,388,1522,2696,54,1914,2456,2455,2454,2453,1924,11,1818,2250,86,1057,2442,1945,2452,2450,2451,2448,2447,155,922,1324,2240,115,147,182,213,2446,2444,2445,2443,2333,2239,2237,2235,2234,2233,2036,2427,672,58,160,699,1196,2196,2232,2231,2005,1994,1992,373,663,1006,1085,1928,1927,1930,1926,1925,321,1991,1990,1989,1988,1987,1102,728,1062,341,1861,1986,1985,1678,1560,869,1644,157,1919,1901,1903,2052,2053,298,836,324,284,270,247,2704,1091,1659,374,421,2255,2256,2257,2258,2259,178,261,1277,1750,1751,123,442,1103,1325,2619,2621,361,1723,1728,1040,1304,1447,2700,2285,2284,2283,2282,2261,581,2280,2279,2278,2277,2281,1386,2275,2276,2265,2270,2268,311,2617,2707,2708,2264,2274,2272,2266,2269,2709,2710,2162,84,724,812,862,2480,346,405,524,2097,2697,8,2262,2263,2267,2712,2336,2550,2557,2341,2546,2483,2482,2481,223,1948,2553,2340,2515,2548,2625,2334,2338,2547,2559,2561,854,276,858,2563,2335,2556,2344,2555,2160,935,2337,2342,2558,2552,2554,1238,520,822,2714,892,2004,2426,2047,2049,2560,2345,2549,2339,2551,2055,94,194,1648,1652,653,278,2220,2001,2562,1848,2726,2719,1854,302,631,1894,1849,1860,168,225,291,318,358,781,706,463,443,420,2717,2716,2728,2734,2723,840,873,400,2715,2722,2727,2718,2729,2739,1461,449,1095,2208,2212,2215,384,1462,1088,995,2740,2479,399,2064,7,1544,1547,660,843,894,2209,2211,1809,1810,2742,2743,2744,2747,2206,2207,2706,2745,2748,2746,2538,3,2749,2750,2751,240,1004,1703,2741,485,2229,826,857,2318,2366,2367,2368,2611,709,1517,2346,2753,2754,2343,755,328,379,417,582,782,742,2760,2759,2761,2762,2006,1900,1411,2146,1453,1165,1227,2752,2756,2755,1616,1618,2766,2147,1451,2148,1437,1899,784,2763,2765,2767,99,317,255,281,1726,1609,1610,56,662,2398,2399,2635,1607,1608,2769,2768,1898,1897,1611,465,2414,2772,2757,2758,2764,2770,2771,2636,1852,1853,2311,2310,2308,2307,2305,336,763,821,2421,1676,2434,2773,2774,2775,153,461,2511,2623,2624,2622,1961,1951,1937,1934,2304,2303,2302,2297,2295,2780,2779,2781,2782,2783,2067,2069,2070,2071,2099,1963,1939,1933,1940,1952,1629,1630,1631,1634,1959,1938,1957,1936,299,654,2788,2785,2786,2787,2789,1157,1548,1649,1718,2510,1960,1935,1943,1941,244,2784,1230,221,703,882,1233,2042,2041,2025,2024,2023,494,1942,280,1954,202,2079,2467,57,93,521,671,1663,2776,2790,2792,2793,2794,2795,77,139,170,1702,1704,1707,1708,1714,2590,2150,1752,1328,1719,1092,2796,566,1755,2016,2797,2798,2799,2800,2801,2802,2803,2804,792,968,1038,1081,1347,383,424,1026,1084,563,1717,2777,2778,2738,611,2054,912,1908,1500,1498,1494,1492,872,1226,1596,1598,1601,1602,1627,570,2535,1753,1488,1485,1483,1480,1373,516,131,175,226,1711,1715,1353,1339,1326,1317,1308,253,2815,2816,2822,695,2040,2149,1716,2814,2824,2825,1294,1279,1270,1268,1264,2817,2818,2331,2323,1372,456,391,665,940,2507,2508,2670,2831,1563,2834,2838,2839,646,798,2084,1018,991,476,1267,1273,1422,1657,2576,2422,2847,469,15,2850,90,2851,2854,70,144,551,2855,605,664,1016,1045,1327,803,1841,1830,1829,827,2859,2512,1993,2858,2690,2860,1471,1469,2861,866,2864,930,668,2013,2415,1962,1394,632,201,616,677,750,823,870,2177,2175,1340,1646,1449,702,1126,1160,1388,2438,2440,2439,601,783,1032,1964,218,2874,2875,1109,1117,681,1232,2061,726,2066,964,2878,232,167,87,649,994,2881,2882,2884,2885,2886,2879,2880,2883,2887,987,1097,2105,2081,1130,1431,2436,1758,2888,2877,2891,2890,1174,2862,2863,1090,467,2893,2894,2895,2867,2869,2870,2871,2872,2892,80,136,209,639,1107,2897,680,615,1307,2898,2873,1154,59,2906,2899,2905,2901,2204,122,741,906,2260,2916,2917,2918,2921,2922,2923,2593,88,1448,1450,1452,2200,2926,2927,2876,254,2449,2903,2919,2101,2416,2417,2931,2929,2932,2933,2934,2935,1709,2925,2937,426,542,598,636,896,2938,2939,1046,1149,1645,1650,1744,975,2940,2630,2631,2924,2902,2904,2908,2911,2943,2942,2941,1600,1635,824,891,1231,2947,2946,2945,2936,1425,1402,1234,92,2951,2953,2389,2960,2958,2955,1811,2949,2954,2957,2474,2473,1505,1504,2959,2961,2963,1812,229,1688,2143,297,319,561,13,2967,2972,2971,2964,2965,2966,2968,1701,1706,2435,2944,2591,2592,2974,2970,2969,1315,2900,2094,132,176,343,1358,1747,1749,2977,2981,2982,2983,1710,1746,186,257,332,372,396,1739,1740,1520,2984,2985,215,523,683,1756,670,693,707,723,739,6,2144,415,9,2370,2986,427,446,2290,2514,369,1162,2987,2992,460,479,856,902,3003,769,775,954,984,1538,2999,2347,2050,2584,1539,1540,2000,2100,2603,3005,2348,3010,497,3014,304,3015,3013,556,800,1128,559,1070,468,3016,645,2993,2289,3017,2914,3004,2928,553,1970,2991,2989,3012,1122,1224,2363,3023,3025,3008,2988,2978,3018,2994,2995,2996,2997,3009,174,1745,1801,3028,2076,3029,2077,578,3037,2413,2412,3039,917,1053,2091,2141,3026,3038,3044,3046,3048,1383,158,3047,198,274,2975,1831,705,2629,3002,3007,3033,3024,3035,1184,971,365,897,1216,1229,1164,1177,1118,3045,1799,1606,2461,2462,2464,2465,1083,1074,1133,2604,3006,2251,1998,2014,490,765,3030,3040,3049,119,222,1116,454,513,624,983,1017,180,850,900,1821,2979,504,594,659,818,838,626,948,1035,1072,1093,1364,1369,366,2857,2973,3041,3042,3043,1043,1080,352,780,804,3036,333,438,1212,237,1253,2849,1331,2832,1170,1250,188,228,283,312,720,2610,3011,2502,2503,2478,2868,729,805,852,933,999,124,227,340,604,669,1013,1051,1059,1187,1195,1244,1247,1200,1215,1208,1263,1484,1479,1478,1477,1472,1333,1228,1285,1296,1314,1322,1181,1819,172,2379,2380,537,1330,1464,1468,1470,880,811,847,1654,932,1889,1890,1896,2662,2856,2865,2457,1534,1910,1529,287,801,137,196,1047,2699,2701,2702,2703,2705,2428,142,2027,216,269,303,350,82,1382,833,807,506,273,1028,1284,2152,2153,1396,2028,2029,2030,2031,2032,2033,2034,2035,104,915,241,957,1179,402,472,431,152,214,249,277,305,2542,2543,510,830,1619,2249,493,565,78,1236,1638,1639,1640,1857,389,368,325,1856,2371,292,860,2210,554,1502,293,608,2187,1765,1780,2180,2407,2182,2181,2823,816,1003,1300,2163,2164,834,982,2051,2058,2059,1612,2506,1862,1866,2230,2115,1802,2386,1256,1902,1204,1207,1193,1198,1186,1189,1166,1175,1269,1276,1278,1283,1292,1436,1435,1434,1433,1432,1430,1427,1420,1417,1416,1410,1415,1409,1408,1406,1403,1404,1401,1349,335,1332,1297,1329,1334,1521,1523,1524,1525,1526,1546,1545,1543,1533,1532,1384,1391,2102,735,2007,2271,2288,1075,1597,1599,1604,2273,2866,2634,2103,1132,1143,1171,1683,531,1695,2037,2294,2293,2296,2300,2301,1762,156,2369,2319,2317,2316,2315,68,66,1720,1741,1742,2098,1792,1794,62,832,846,1039,966,1636,1027,1077,64,282,1073,117]
async function findAffected() {
  const accounts = await ethers.getSigners()
  const contract = await ethers.getContractAt("HealerHayley", "0x56b5d7a82b475b969e09fc9352350c1921361a39", accounts[0])
  const inc = 100;
  let fixed = 0;
  while (fixed < affectedIds.length) {
    console.log(`Fixing ${fixed} to ${fixed+inc}`)
    const tx = await contract.setAffected(affectedIds.slice(fixed, fixed+inc));
    await tx.wait(1);
    fixed += inc;
  }

  return;
  //const accounts = await ethers.getSigners()
  //const contract = await ethers.getContractAt("EvoUpgradeable", "0x454a0e479ac78e508a95880216c06f50bf3c321c", accounts[0])

  const filter = contract.filters.Transfer(ADDRESS_ZERO)

  const toBlock = 17382991;
  const fromBlock = 17335227;
  const affectedList = [];
  let totalDelta = toBlock - fromBlock;
  let blockDelta = totalDelta;
  let from = fromBlock
  let to = from ;
  if (blockDelta > 1024) {
    to = from + 1024
  }
  let scanned = 0
  while (from <= toBlock) {
    console.log("Blocks to scan:", blockDelta)
    console.log(`Getting events from ${from} to ${to} | ${Math.round(scanned / totalDelta * 100)}% complete`)
    const events = await contract.queryFilter(filter, from, to)
    scanned += to - from
    blockDelta -= to - from
    from = to + 1
    to = blockDelta > 1024 ? from + 1024 : toBlock;
    for (const event of events) {
      affectedList.push(event.args.tokenId.toNumber())
    }
  }
  console.log(`Eggs affected: ${affectedList.length}`)
  console.log(`Egg Ids:`, affectedList)
  process.stdout.write(JSON.stringify(affectedList) + '\n');
}

findAffected()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
