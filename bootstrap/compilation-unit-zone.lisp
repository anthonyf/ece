;;;; bootstrap/compilation-unit-zone.lisp
;;;;
;;;; AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND.
;;;;
;;;; Source space: compilation-unit
;;;; Generator: src/codegen-cl-inline.scm
;;;; Regenerate: make bootstrap/compilation-unit-zone.lisp
;;;;
;;;; The CL runtime loads this file at boot and registers the defun
;;;; below under its space symbol in *compiled-zone-functions*.

(in-package :ece)

(defun zone-compilation-unit-chunk-0 (initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)
  (cl:let ((pc initial-pc)
           (val initial-val)
           (env initial-env)
           (proc initial-proc)
           (argl initial-argl)
           (continue initial-continue)
           (stack initial-stack)
           (flag cl:nil)
           (bail cl:nil))
    (cl:declare (cl:type cl:fixnum pc) (cl:ignorable flag bail))
    (cl:tagbody
     (cl:cond
       ((cl:< pc 256)
        (cl:case pc
          (0 (cl:go pc-0))
          (1 (cl:go pc-1))
          (2 (cl:go pc-2))
          (3 (cl:go pc-3))
          (4 (cl:go pc-4))
          (5 (cl:go pc-5))
          (6 (cl:go pc-6))
          (7 (cl:go pc-7))
          (8 (cl:go pc-8))
          (9 (cl:go pc-9))
          (10 (cl:go pc-10))
          (11 (cl:go pc-11))
          (12 (cl:go pc-12))
          (13 (cl:go pc-13))
          (14 (cl:go pc-14))
          (15 (cl:go pc-15))
          (16 (cl:go pc-16))
          (17 (cl:go pc-17))
          (18 (cl:go pc-18))
          (19 (cl:go pc-19))
          (20 (cl:go pc-20))
          (21 (cl:go pc-21))
          (22 (cl:go pc-22))
          (23 (cl:go pc-23))
          (24 (cl:go pc-24))
          (25 (cl:go pc-25))
          (26 (cl:go pc-26))
          (27 (cl:go pc-27))
          (28 (cl:go pc-28))
          (29 (cl:go pc-29))
          (30 (cl:go pc-30))
          (31 (cl:go pc-31))
          (32 (cl:go pc-32))
          (33 (cl:go pc-33))
          (34 (cl:go pc-34))
          (35 (cl:go pc-35))
          (36 (cl:go pc-36))
          (37 (cl:go pc-37))
          (38 (cl:go pc-38))
          (39 (cl:go pc-39))
          (40 (cl:go pc-40))
          (41 (cl:go pc-41))
          (42 (cl:go pc-42))
          (43 (cl:go pc-43))
          (44 (cl:go pc-44))
          (45 (cl:go pc-45))
          (46 (cl:go pc-46))
          (47 (cl:go pc-47))
          (48 (cl:go pc-48))
          (49 (cl:go pc-49))
          (50 (cl:go pc-50))
          (51 (cl:go pc-51))
          (52 (cl:go pc-52))
          (53 (cl:go pc-53))
          (54 (cl:go pc-54))
          (55 (cl:go pc-55))
          (56 (cl:go pc-56))
          (57 (cl:go pc-57))
          (58 (cl:go pc-58))
          (59 (cl:go pc-59))
          (60 (cl:go pc-60))
          (61 (cl:go pc-61))
          (62 (cl:go pc-62))
          (63 (cl:go pc-63))
          (64 (cl:go pc-64))
          (65 (cl:go pc-65))
          (66 (cl:go pc-66))
          (67 (cl:go pc-67))
          (68 (cl:go pc-68))
          (69 (cl:go pc-69))
          (70 (cl:go pc-70))
          (71 (cl:go pc-71))
          (72 (cl:go pc-72))
          (73 (cl:go pc-73))
          (74 (cl:go pc-74))
          (75 (cl:go pc-75))
          (76 (cl:go pc-76))
          (77 (cl:go pc-77))
          (78 (cl:go pc-78))
          (79 (cl:go pc-79))
          (80 (cl:go pc-80))
          (81 (cl:go pc-81))
          (82 (cl:go pc-82))
          (83 (cl:go pc-83))
          (84 (cl:go pc-84))
          (85 (cl:go pc-85))
          (86 (cl:go pc-86))
          (87 (cl:go pc-87))
          (88 (cl:go pc-88))
          (89 (cl:go pc-89))
          (90 (cl:go pc-90))
          (91 (cl:go pc-91))
          (92 (cl:go pc-92))
          (93 (cl:go pc-93))
          (94 (cl:go pc-94))
          (95 (cl:go pc-95))
          (96 (cl:go pc-96))
          (97 (cl:go pc-97))
          (98 (cl:go pc-98))
          (99 (cl:go pc-99))
          (100 (cl:go pc-100))
          (101 (cl:go pc-101))
          (102 (cl:go pc-102))
          (103 (cl:go pc-103))
          (104 (cl:go pc-104))
          (105 (cl:go pc-105))
          (106 (cl:go pc-106))
          (107 (cl:go pc-107))
          (108 (cl:go pc-108))
          (109 (cl:go pc-109))
          (110 (cl:go pc-110))
          (111 (cl:go pc-111))
          (112 (cl:go pc-112))
          (113 (cl:go pc-113))
          (114 (cl:go pc-114))
          (115 (cl:go pc-115))
          (116 (cl:go pc-116))
          (117 (cl:go pc-117))
          (118 (cl:go pc-118))
          (119 (cl:go pc-119))
          (120 (cl:go pc-120))
          (121 (cl:go pc-121))
          (122 (cl:go pc-122))
          (123 (cl:go pc-123))
          (124 (cl:go pc-124))
          (125 (cl:go pc-125))
          (126 (cl:go pc-126))
          (127 (cl:go pc-127))
          (128 (cl:go pc-128))
          (129 (cl:go pc-129))
          (130 (cl:go pc-130))
          (131 (cl:go pc-131))
          (132 (cl:go pc-132))
          (133 (cl:go pc-133))
          (134 (cl:go pc-134))
          (135 (cl:go pc-135))
          (136 (cl:go pc-136))
          (137 (cl:go pc-137))
          (138 (cl:go pc-138))
          (139 (cl:go pc-139))
          (140 (cl:go pc-140))
          (141 (cl:go pc-141))
          (142 (cl:go pc-142))
          (143 (cl:go pc-143))
          (144 (cl:go pc-144))
          (145 (cl:go pc-145))
          (146 (cl:go pc-146))
          (147 (cl:go pc-147))
          (148 (cl:go pc-148))
          (149 (cl:go pc-149))
          (150 (cl:go pc-150))
          (151 (cl:go pc-151))
          (152 (cl:go pc-152))
          (153 (cl:go pc-153))
          (154 (cl:go pc-154))
          (155 (cl:go pc-155))
          (156 (cl:go pc-156))
          (157 (cl:go pc-157))
          (158 (cl:go pc-158))
          (159 (cl:go pc-159))
          (160 (cl:go pc-160))
          (161 (cl:go pc-161))
          (162 (cl:go pc-162))
          (163 (cl:go pc-163))
          (164 (cl:go pc-164))
          (165 (cl:go pc-165))
          (166 (cl:go pc-166))
          (167 (cl:go pc-167))
          (168 (cl:go pc-168))
          (169 (cl:go pc-169))
          (170 (cl:go pc-170))
          (171 (cl:go pc-171))
          (172 (cl:go pc-172))
          (173 (cl:go pc-173))
          (174 (cl:go pc-174))
          (175 (cl:go pc-175))
          (176 (cl:go pc-176))
          (177 (cl:go pc-177))
          (178 (cl:go pc-178))
          (179 (cl:go pc-179))
          (180 (cl:go pc-180))
          (181 (cl:go pc-181))
          (182 (cl:go pc-182))
          (183 (cl:go pc-183))
          (184 (cl:go pc-184))
          (185 (cl:go pc-185))
          (186 (cl:go pc-186))
          (187 (cl:go pc-187))
          (188 (cl:go pc-188))
          (189 (cl:go pc-189))
          (190 (cl:go pc-190))
          (191 (cl:go pc-191))
          (192 (cl:go pc-192))
          (193 (cl:go pc-193))
          (194 (cl:go pc-194))
          (195 (cl:go pc-195))
          (196 (cl:go pc-196))
          (197 (cl:go pc-197))
          (198 (cl:go pc-198))
          (199 (cl:go pc-199))
          (200 (cl:go pc-200))
          (201 (cl:go pc-201))
          (202 (cl:go pc-202))
          (203 (cl:go pc-203))
          (204 (cl:go pc-204))
          (205 (cl:go pc-205))
          (206 (cl:go pc-206))
          (207 (cl:go pc-207))
          (208 (cl:go pc-208))
          (209 (cl:go pc-209))
          (210 (cl:go pc-210))
          (211 (cl:go pc-211))
          (212 (cl:go pc-212))
          (213 (cl:go pc-213))
          (214 (cl:go pc-214))
          (215 (cl:go pc-215))
          (216 (cl:go pc-216))
          (217 (cl:go pc-217))
          (218 (cl:go pc-218))
          (219 (cl:go pc-219))
          (220 (cl:go pc-220))
          (221 (cl:go pc-221))
          (222 (cl:go pc-222))
          (223 (cl:go pc-223))
          (224 (cl:go pc-224))
          (225 (cl:go pc-225))
          (226 (cl:go pc-226))
          (227 (cl:go pc-227))
          (228 (cl:go pc-228))
          (229 (cl:go pc-229))
          (230 (cl:go pc-230))
          (231 (cl:go pc-231))
          (232 (cl:go pc-232))
          (233 (cl:go pc-233))
          (234 (cl:go pc-234))
          (235 (cl:go pc-235))
          (236 (cl:go pc-236))
          (237 (cl:go pc-237))
          (238 (cl:go pc-238))
          (239 (cl:go pc-239))
          (240 (cl:go pc-240))
          (241 (cl:go pc-241))
          (242 (cl:go pc-242))
          (243 (cl:go pc-243))
          (244 (cl:go pc-244))
          (245 (cl:go pc-245))
          (246 (cl:go pc-246))
          (247 (cl:go pc-247))
          (248 (cl:go pc-248))
          (249 (cl:go pc-249))
          (250 (cl:go pc-250))
          (251 (cl:go pc-251))
          (252 (cl:go pc-252))
          (253 (cl:go pc-253))
          (254 (cl:go pc-254))
          (255 (cl:go pc-255))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 512)
        (cl:case pc
          (256 (cl:go pc-256))
          (257 (cl:go pc-257))
          (258 (cl:go pc-258))
          (259 (cl:go pc-259))
          (260 (cl:go pc-260))
          (261 (cl:go pc-261))
          (262 (cl:go pc-262))
          (263 (cl:go pc-263))
          (264 (cl:go pc-264))
          (265 (cl:go pc-265))
          (266 (cl:go pc-266))
          (267 (cl:go pc-267))
          (268 (cl:go pc-268))
          (269 (cl:go pc-269))
          (270 (cl:go pc-270))
          (271 (cl:go pc-271))
          (272 (cl:go pc-272))
          (273 (cl:go pc-273))
          (274 (cl:go pc-274))
          (275 (cl:go pc-275))
          (276 (cl:go pc-276))
          (277 (cl:go pc-277))
          (278 (cl:go pc-278))
          (279 (cl:go pc-279))
          (280 (cl:go pc-280))
          (281 (cl:go pc-281))
          (282 (cl:go pc-282))
          (283 (cl:go pc-283))
          (284 (cl:go pc-284))
          (285 (cl:go pc-285))
          (286 (cl:go pc-286))
          (287 (cl:go pc-287))
          (288 (cl:go pc-288))
          (289 (cl:go pc-289))
          (290 (cl:go pc-290))
          (291 (cl:go pc-291))
          (292 (cl:go pc-292))
          (293 (cl:go pc-293))
          (294 (cl:go pc-294))
          (295 (cl:go pc-295))
          (296 (cl:go pc-296))
          (297 (cl:go pc-297))
          (298 (cl:go pc-298))
          (299 (cl:go pc-299))
          (300 (cl:go pc-300))
          (301 (cl:go pc-301))
          (302 (cl:go pc-302))
          (303 (cl:go pc-303))
          (304 (cl:go pc-304))
          (305 (cl:go pc-305))
          (306 (cl:go pc-306))
          (307 (cl:go pc-307))
          (308 (cl:go pc-308))
          (309 (cl:go pc-309))
          (310 (cl:go pc-310))
          (311 (cl:go pc-311))
          (312 (cl:go pc-312))
          (313 (cl:go pc-313))
          (314 (cl:go pc-314))
          (315 (cl:go pc-315))
          (316 (cl:go pc-316))
          (317 (cl:go pc-317))
          (318 (cl:go pc-318))
          (319 (cl:go pc-319))
          (320 (cl:go pc-320))
          (321 (cl:go pc-321))
          (322 (cl:go pc-322))
          (323 (cl:go pc-323))
          (324 (cl:go pc-324))
          (325 (cl:go pc-325))
          (326 (cl:go pc-326))
          (327 (cl:go pc-327))
          (328 (cl:go pc-328))
          (329 (cl:go pc-329))
          (330 (cl:go pc-330))
          (331 (cl:go pc-331))
          (332 (cl:go pc-332))
          (333 (cl:go pc-333))
          (334 (cl:go pc-334))
          (335 (cl:go pc-335))
          (336 (cl:go pc-336))
          (337 (cl:go pc-337))
          (338 (cl:go pc-338))
          (339 (cl:go pc-339))
          (340 (cl:go pc-340))
          (341 (cl:go pc-341))
          (342 (cl:go pc-342))
          (343 (cl:go pc-343))
          (344 (cl:go pc-344))
          (345 (cl:go pc-345))
          (346 (cl:go pc-346))
          (347 (cl:go pc-347))
          (348 (cl:go pc-348))
          (349 (cl:go pc-349))
          (350 (cl:go pc-350))
          (351 (cl:go pc-351))
          (352 (cl:go pc-352))
          (353 (cl:go pc-353))
          (354 (cl:go pc-354))
          (355 (cl:go pc-355))
          (356 (cl:go pc-356))
          (357 (cl:go pc-357))
          (358 (cl:go pc-358))
          (359 (cl:go pc-359))
          (360 (cl:go pc-360))
          (361 (cl:go pc-361))
          (362 (cl:go pc-362))
          (363 (cl:go pc-363))
          (364 (cl:go pc-364))
          (365 (cl:go pc-365))
          (366 (cl:go pc-366))
          (367 (cl:go pc-367))
          (368 (cl:go pc-368))
          (369 (cl:go pc-369))
          (370 (cl:go pc-370))
          (371 (cl:go pc-371))
          (372 (cl:go pc-372))
          (373 (cl:go pc-373))
          (374 (cl:go pc-374))
          (375 (cl:go pc-375))
          (376 (cl:go pc-376))
          (377 (cl:go pc-377))
          (378 (cl:go pc-378))
          (379 (cl:go pc-379))
          (380 (cl:go pc-380))
          (381 (cl:go pc-381))
          (382 (cl:go pc-382))
          (383 (cl:go pc-383))
          (384 (cl:go pc-384))
          (385 (cl:go pc-385))
          (386 (cl:go pc-386))
          (387 (cl:go pc-387))
          (388 (cl:go pc-388))
          (389 (cl:go pc-389))
          (390 (cl:go pc-390))
          (391 (cl:go pc-391))
          (392 (cl:go pc-392))
          (393 (cl:go pc-393))
          (394 (cl:go pc-394))
          (395 (cl:go pc-395))
          (396 (cl:go pc-396))
          (397 (cl:go pc-397))
          (398 (cl:go pc-398))
          (399 (cl:go pc-399))
          (400 (cl:go pc-400))
          (401 (cl:go pc-401))
          (402 (cl:go pc-402))
          (403 (cl:go pc-403))
          (404 (cl:go pc-404))
          (405 (cl:go pc-405))
          (406 (cl:go pc-406))
          (407 (cl:go pc-407))
          (408 (cl:go pc-408))
          (409 (cl:go pc-409))
          (410 (cl:go pc-410))
          (411 (cl:go pc-411))
          (412 (cl:go pc-412))
          (413 (cl:go pc-413))
          (414 (cl:go pc-414))
          (415 (cl:go pc-415))
          (416 (cl:go pc-416))
          (417 (cl:go pc-417))
          (418 (cl:go pc-418))
          (419 (cl:go pc-419))
          (420 (cl:go pc-420))
          (421 (cl:go pc-421))
          (422 (cl:go pc-422))
          (423 (cl:go pc-423))
          (424 (cl:go pc-424))
          (425 (cl:go pc-425))
          (426 (cl:go pc-426))
          (427 (cl:go pc-427))
          (428 (cl:go pc-428))
          (429 (cl:go pc-429))
          (430 (cl:go pc-430))
          (431 (cl:go pc-431))
          (432 (cl:go pc-432))
          (433 (cl:go pc-433))
          (434 (cl:go pc-434))
          (435 (cl:go pc-435))
          (436 (cl:go pc-436))
          (437 (cl:go pc-437))
          (438 (cl:go pc-438))
          (439 (cl:go pc-439))
          (440 (cl:go pc-440))
          (441 (cl:go pc-441))
          (442 (cl:go pc-442))
          (443 (cl:go pc-443))
          (444 (cl:go pc-444))
          (445 (cl:go pc-445))
          (446 (cl:go pc-446))
          (447 (cl:go pc-447))
          (448 (cl:go pc-448))
          (449 (cl:go pc-449))
          (450 (cl:go pc-450))
          (451 (cl:go pc-451))
          (452 (cl:go pc-452))
          (453 (cl:go pc-453))
          (454 (cl:go pc-454))
          (455 (cl:go pc-455))
          (456 (cl:go pc-456))
          (457 (cl:go pc-457))
          (458 (cl:go pc-458))
          (459 (cl:go pc-459))
          (460 (cl:go pc-460))
          (461 (cl:go pc-461))
          (462 (cl:go pc-462))
          (463 (cl:go pc-463))
          (464 (cl:go pc-464))
          (465 (cl:go pc-465))
          (466 (cl:go pc-466))
          (467 (cl:go pc-467))
          (468 (cl:go pc-468))
          (469 (cl:go pc-469))
          (470 (cl:go pc-470))
          (471 (cl:go pc-471))
          (472 (cl:go pc-472))
          (473 (cl:go pc-473))
          (474 (cl:go pc-474))
          (475 (cl:go pc-475))
          (476 (cl:go pc-476))
          (477 (cl:go pc-477))
          (478 (cl:go pc-478))
          (479 (cl:go pc-479))
          (480 (cl:go pc-480))
          (481 (cl:go pc-481))
          (482 (cl:go pc-482))
          (483 (cl:go pc-483))
          (484 (cl:go pc-484))
          (485 (cl:go pc-485))
          (486 (cl:go pc-486))
          (487 (cl:go pc-487))
          (488 (cl:go pc-488))
          (489 (cl:go pc-489))
          (490 (cl:go pc-490))
          (491 (cl:go pc-491))
          (492 (cl:go pc-492))
          (493 (cl:go pc-493))
          (494 (cl:go pc-494))
          (495 (cl:go pc-495))
          (496 (cl:go pc-496))
          (497 (cl:go pc-497))
          (498 (cl:go pc-498))
          (499 (cl:go pc-499))
          (500 (cl:go pc-500))
          (501 (cl:go pc-501))
          (502 (cl:go pc-502))
          (503 (cl:go pc-503))
          (504 (cl:go pc-504))
          (505 (cl:go pc-505))
          (506 (cl:go pc-506))
          (507 (cl:go pc-507))
          (508 (cl:go pc-508))
          (509 (cl:go pc-509))
          (510 (cl:go pc-510))
          (511 (cl:go pc-511))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 768)
        (cl:case pc
          (512 (cl:go pc-512))
          (513 (cl:go pc-513))
          (514 (cl:go pc-514))
          (515 (cl:go pc-515))
          (516 (cl:go pc-516))
          (517 (cl:go pc-517))
          (518 (cl:go pc-518))
          (519 (cl:go pc-519))
          (520 (cl:go pc-520))
          (521 (cl:go pc-521))
          (522 (cl:go pc-522))
          (523 (cl:go pc-523))
          (524 (cl:go pc-524))
          (525 (cl:go pc-525))
          (526 (cl:go pc-526))
          (527 (cl:go pc-527))
          (528 (cl:go pc-528))
          (529 (cl:go pc-529))
          (530 (cl:go pc-530))
          (531 (cl:go pc-531))
          (532 (cl:go pc-532))
          (533 (cl:go pc-533))
          (534 (cl:go pc-534))
          (535 (cl:go pc-535))
          (536 (cl:go pc-536))
          (537 (cl:go pc-537))
          (538 (cl:go pc-538))
          (539 (cl:go pc-539))
          (540 (cl:go pc-540))
          (541 (cl:go pc-541))
          (542 (cl:go pc-542))
          (543 (cl:go pc-543))
          (544 (cl:go pc-544))
          (545 (cl:go pc-545))
          (546 (cl:go pc-546))
          (547 (cl:go pc-547))
          (548 (cl:go pc-548))
          (549 (cl:go pc-549))
          (550 (cl:go pc-550))
          (551 (cl:go pc-551))
          (552 (cl:go pc-552))
          (553 (cl:go pc-553))
          (554 (cl:go pc-554))
          (555 (cl:go pc-555))
          (556 (cl:go pc-556))
          (557 (cl:go pc-557))
          (558 (cl:go pc-558))
          (559 (cl:go pc-559))
          (560 (cl:go pc-560))
          (561 (cl:go pc-561))
          (562 (cl:go pc-562))
          (563 (cl:go pc-563))
          (564 (cl:go pc-564))
          (565 (cl:go pc-565))
          (566 (cl:go pc-566))
          (567 (cl:go pc-567))
          (568 (cl:go pc-568))
          (569 (cl:go pc-569))
          (570 (cl:go pc-570))
          (571 (cl:go pc-571))
          (572 (cl:go pc-572))
          (573 (cl:go pc-573))
          (574 (cl:go pc-574))
          (575 (cl:go pc-575))
          (576 (cl:go pc-576))
          (577 (cl:go pc-577))
          (578 (cl:go pc-578))
          (579 (cl:go pc-579))
          (580 (cl:go pc-580))
          (581 (cl:go pc-581))
          (582 (cl:go pc-582))
          (583 (cl:go pc-583))
          (584 (cl:go pc-584))
          (585 (cl:go pc-585))
          (586 (cl:go pc-586))
          (587 (cl:go pc-587))
          (588 (cl:go pc-588))
          (589 (cl:go pc-589))
          (590 (cl:go pc-590))
          (591 (cl:go pc-591))
          (592 (cl:go pc-592))
          (593 (cl:go pc-593))
          (594 (cl:go pc-594))
          (595 (cl:go pc-595))
          (596 (cl:go pc-596))
          (597 (cl:go pc-597))
          (598 (cl:go pc-598))
          (599 (cl:go pc-599))
          (600 (cl:go pc-600))
          (601 (cl:go pc-601))
          (602 (cl:go pc-602))
          (603 (cl:go pc-603))
          (604 (cl:go pc-604))
          (605 (cl:go pc-605))
          (606 (cl:go pc-606))
          (607 (cl:go pc-607))
          (608 (cl:go pc-608))
          (609 (cl:go pc-609))
          (610 (cl:go pc-610))
          (611 (cl:go pc-611))
          (612 (cl:go pc-612))
          (613 (cl:go pc-613))
          (614 (cl:go pc-614))
          (615 (cl:go pc-615))
          (616 (cl:go pc-616))
          (617 (cl:go pc-617))
          (618 (cl:go pc-618))
          (619 (cl:go pc-619))
          (620 (cl:go pc-620))
          (621 (cl:go pc-621))
          (622 (cl:go pc-622))
          (623 (cl:go pc-623))
          (624 (cl:go pc-624))
          (625 (cl:go pc-625))
          (626 (cl:go pc-626))
          (627 (cl:go pc-627))
          (628 (cl:go pc-628))
          (629 (cl:go pc-629))
          (630 (cl:go pc-630))
          (631 (cl:go pc-631))
          (632 (cl:go pc-632))
          (633 (cl:go pc-633))
          (634 (cl:go pc-634))
          (635 (cl:go pc-635))
          (636 (cl:go pc-636))
          (637 (cl:go pc-637))
          (638 (cl:go pc-638))
          (639 (cl:go pc-639))
          (640 (cl:go pc-640))
          (641 (cl:go pc-641))
          (642 (cl:go pc-642))
          (643 (cl:go pc-643))
          (644 (cl:go pc-644))
          (645 (cl:go pc-645))
          (646 (cl:go pc-646))
          (647 (cl:go pc-647))
          (648 (cl:go pc-648))
          (649 (cl:go pc-649))
          (650 (cl:go pc-650))
          (651 (cl:go pc-651))
          (652 (cl:go pc-652))
          (653 (cl:go pc-653))
          (654 (cl:go pc-654))
          (655 (cl:go pc-655))
          (656 (cl:go pc-656))
          (657 (cl:go pc-657))
          (658 (cl:go pc-658))
          (659 (cl:go pc-659))
          (660 (cl:go pc-660))
          (661 (cl:go pc-661))
          (662 (cl:go pc-662))
          (663 (cl:go pc-663))
          (664 (cl:go pc-664))
          (665 (cl:go pc-665))
          (666 (cl:go pc-666))
          (667 (cl:go pc-667))
          (668 (cl:go pc-668))
          (669 (cl:go pc-669))
          (670 (cl:go pc-670))
          (671 (cl:go pc-671))
          (672 (cl:go pc-672))
          (673 (cl:go pc-673))
          (674 (cl:go pc-674))
          (675 (cl:go pc-675))
          (676 (cl:go pc-676))
          (677 (cl:go pc-677))
          (678 (cl:go pc-678))
          (679 (cl:go pc-679))
          (680 (cl:go pc-680))
          (681 (cl:go pc-681))
          (682 (cl:go pc-682))
          (683 (cl:go pc-683))
          (684 (cl:go pc-684))
          (685 (cl:go pc-685))
          (686 (cl:go pc-686))
          (687 (cl:go pc-687))
          (688 (cl:go pc-688))
          (689 (cl:go pc-689))
          (690 (cl:go pc-690))
          (691 (cl:go pc-691))
          (692 (cl:go pc-692))
          (693 (cl:go pc-693))
          (694 (cl:go pc-694))
          (695 (cl:go pc-695))
          (696 (cl:go pc-696))
          (697 (cl:go pc-697))
          (698 (cl:go pc-698))
          (699 (cl:go pc-699))
          (700 (cl:go pc-700))
          (701 (cl:go pc-701))
          (702 (cl:go pc-702))
          (703 (cl:go pc-703))
          (704 (cl:go pc-704))
          (705 (cl:go pc-705))
          (706 (cl:go pc-706))
          (707 (cl:go pc-707))
          (708 (cl:go pc-708))
          (709 (cl:go pc-709))
          (710 (cl:go pc-710))
          (711 (cl:go pc-711))
          (712 (cl:go pc-712))
          (713 (cl:go pc-713))
          (714 (cl:go pc-714))
          (715 (cl:go pc-715))
          (716 (cl:go pc-716))
          (717 (cl:go pc-717))
          (718 (cl:go pc-718))
          (719 (cl:go pc-719))
          (720 (cl:go pc-720))
          (721 (cl:go pc-721))
          (722 (cl:go pc-722))
          (723 (cl:go pc-723))
          (724 (cl:go pc-724))
          (725 (cl:go pc-725))
          (726 (cl:go pc-726))
          (727 (cl:go pc-727))
          (728 (cl:go pc-728))
          (729 (cl:go pc-729))
          (730 (cl:go pc-730))
          (731 (cl:go pc-731))
          (732 (cl:go pc-732))
          (733 (cl:go pc-733))
          (734 (cl:go pc-734))
          (735 (cl:go pc-735))
          (736 (cl:go pc-736))
          (737 (cl:go pc-737))
          (738 (cl:go pc-738))
          (739 (cl:go pc-739))
          (740 (cl:go pc-740))
          (741 (cl:go pc-741))
          (742 (cl:go pc-742))
          (743 (cl:go pc-743))
          (744 (cl:go pc-744))
          (745 (cl:go pc-745))
          (746 (cl:go pc-746))
          (747 (cl:go pc-747))
          (748 (cl:go pc-748))
          (749 (cl:go pc-749))
          (750 (cl:go pc-750))
          (751 (cl:go pc-751))
          (752 (cl:go pc-752))
          (753 (cl:go pc-753))
          (754 (cl:go pc-754))
          (755 (cl:go pc-755))
          (756 (cl:go pc-756))
          (757 (cl:go pc-757))
          (758 (cl:go pc-758))
          (759 (cl:go pc-759))
          (760 (cl:go pc-760))
          (761 (cl:go pc-761))
          (762 (cl:go pc-762))
          (763 (cl:go pc-763))
          (764 (cl:go pc-764))
          (765 (cl:go pc-765))
          (766 (cl:go pc-766))
          (767 (cl:go pc-767))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 1024)
        (cl:case pc
          (768 (cl:go pc-768))
          (769 (cl:go pc-769))
          (770 (cl:go pc-770))
          (771 (cl:go pc-771))
          (772 (cl:go pc-772))
          (773 (cl:go pc-773))
          (774 (cl:go pc-774))
          (775 (cl:go pc-775))
          (776 (cl:go pc-776))
          (777 (cl:go pc-777))
          (778 (cl:go pc-778))
          (779 (cl:go pc-779))
          (780 (cl:go pc-780))
          (781 (cl:go pc-781))
          (782 (cl:go pc-782))
          (783 (cl:go pc-783))
          (784 (cl:go pc-784))
          (785 (cl:go pc-785))
          (786 (cl:go pc-786))
          (787 (cl:go pc-787))
          (788 (cl:go pc-788))
          (789 (cl:go pc-789))
          (790 (cl:go pc-790))
          (791 (cl:go pc-791))
          (792 (cl:go pc-792))
          (793 (cl:go pc-793))
          (794 (cl:go pc-794))
          (795 (cl:go pc-795))
          (796 (cl:go pc-796))
          (797 (cl:go pc-797))
          (798 (cl:go pc-798))
          (799 (cl:go pc-799))
          (800 (cl:go pc-800))
          (801 (cl:go pc-801))
          (802 (cl:go pc-802))
          (803 (cl:go pc-803))
          (804 (cl:go pc-804))
          (805 (cl:go pc-805))
          (806 (cl:go pc-806))
          (807 (cl:go pc-807))
          (808 (cl:go pc-808))
          (809 (cl:go pc-809))
          (810 (cl:go pc-810))
          (811 (cl:go pc-811))
          (812 (cl:go pc-812))
          (813 (cl:go pc-813))
          (814 (cl:go pc-814))
          (815 (cl:go pc-815))
          (816 (cl:go pc-816))
          (817 (cl:go pc-817))
          (818 (cl:go pc-818))
          (819 (cl:go pc-819))
          (820 (cl:go pc-820))
          (821 (cl:go pc-821))
          (822 (cl:go pc-822))
          (823 (cl:go pc-823))
          (824 (cl:go pc-824))
          (825 (cl:go pc-825))
          (826 (cl:go pc-826))
          (827 (cl:go pc-827))
          (828 (cl:go pc-828))
          (829 (cl:go pc-829))
          (830 (cl:go pc-830))
          (831 (cl:go pc-831))
          (832 (cl:go pc-832))
          (833 (cl:go pc-833))
          (834 (cl:go pc-834))
          (835 (cl:go pc-835))
          (836 (cl:go pc-836))
          (837 (cl:go pc-837))
          (838 (cl:go pc-838))
          (839 (cl:go pc-839))
          (840 (cl:go pc-840))
          (841 (cl:go pc-841))
          (842 (cl:go pc-842))
          (843 (cl:go pc-843))
          (844 (cl:go pc-844))
          (845 (cl:go pc-845))
          (846 (cl:go pc-846))
          (847 (cl:go pc-847))
          (848 (cl:go pc-848))
          (849 (cl:go pc-849))
          (850 (cl:go pc-850))
          (851 (cl:go pc-851))
          (852 (cl:go pc-852))
          (853 (cl:go pc-853))
          (854 (cl:go pc-854))
          (855 (cl:go pc-855))
          (856 (cl:go pc-856))
          (857 (cl:go pc-857))
          (858 (cl:go pc-858))
          (859 (cl:go pc-859))
          (860 (cl:go pc-860))
          (861 (cl:go pc-861))
          (862 (cl:go pc-862))
          (863 (cl:go pc-863))
          (864 (cl:go pc-864))
          (865 (cl:go pc-865))
          (866 (cl:go pc-866))
          (867 (cl:go pc-867))
          (868 (cl:go pc-868))
          (869 (cl:go pc-869))
          (870 (cl:go pc-870))
          (871 (cl:go pc-871))
          (872 (cl:go pc-872))
          (873 (cl:go pc-873))
          (874 (cl:go pc-874))
          (875 (cl:go pc-875))
          (876 (cl:go pc-876))
          (877 (cl:go pc-877))
          (878 (cl:go pc-878))
          (879 (cl:go pc-879))
          (880 (cl:go pc-880))
          (881 (cl:go pc-881))
          (882 (cl:go pc-882))
          (883 (cl:go pc-883))
          (884 (cl:go pc-884))
          (885 (cl:go pc-885))
          (886 (cl:go pc-886))
          (887 (cl:go pc-887))
          (888 (cl:go pc-888))
          (889 (cl:go pc-889))
          (890 (cl:go pc-890))
          (891 (cl:go pc-891))
          (892 (cl:go pc-892))
          (893 (cl:go pc-893))
          (894 (cl:go pc-894))
          (895 (cl:go pc-895))
          (896 (cl:go pc-896))
          (897 (cl:go pc-897))
          (898 (cl:go pc-898))
          (899 (cl:go pc-899))
          (900 (cl:go pc-900))
          (901 (cl:go pc-901))
          (902 (cl:go pc-902))
          (903 (cl:go pc-903))
          (904 (cl:go pc-904))
          (905 (cl:go pc-905))
          (906 (cl:go pc-906))
          (907 (cl:go pc-907))
          (908 (cl:go pc-908))
          (909 (cl:go pc-909))
          (910 (cl:go pc-910))
          (911 (cl:go pc-911))
          (912 (cl:go pc-912))
          (913 (cl:go pc-913))
          (914 (cl:go pc-914))
          (915 (cl:go pc-915))
          (916 (cl:go pc-916))
          (917 (cl:go pc-917))
          (918 (cl:go pc-918))
          (919 (cl:go pc-919))
          (920 (cl:go pc-920))
          (921 (cl:go pc-921))
          (922 (cl:go pc-922))
          (923 (cl:go pc-923))
          (924 (cl:go pc-924))
          (925 (cl:go pc-925))
          (926 (cl:go pc-926))
          (927 (cl:go pc-927))
          (928 (cl:go pc-928))
          (929 (cl:go pc-929))
          (930 (cl:go pc-930))
          (931 (cl:go pc-931))
          (932 (cl:go pc-932))
          (933 (cl:go pc-933))
          (934 (cl:go pc-934))
          (935 (cl:go pc-935))
          (936 (cl:go pc-936))
          (937 (cl:go pc-937))
          (938 (cl:go pc-938))
          (939 (cl:go pc-939))
          (940 (cl:go pc-940))
          (941 (cl:go pc-941))
          (942 (cl:go pc-942))
          (943 (cl:go pc-943))
          (944 (cl:go pc-944))
          (945 (cl:go pc-945))
          (946 (cl:go pc-946))
          (947 (cl:go pc-947))
          (948 (cl:go pc-948))
          (949 (cl:go pc-949))
          (950 (cl:go pc-950))
          (951 (cl:go pc-951))
          (952 (cl:go pc-952))
          (953 (cl:go pc-953))
          (954 (cl:go pc-954))
          (955 (cl:go pc-955))
          (956 (cl:go pc-956))
          (957 (cl:go pc-957))
          (958 (cl:go pc-958))
          (959 (cl:go pc-959))
          (960 (cl:go pc-960))
          (961 (cl:go pc-961))
          (962 (cl:go pc-962))
          (963 (cl:go pc-963))
          (964 (cl:go pc-964))
          (965 (cl:go pc-965))
          (966 (cl:go pc-966))
          (967 (cl:go pc-967))
          (968 (cl:go pc-968))
          (969 (cl:go pc-969))
          (970 (cl:go pc-970))
          (971 (cl:go pc-971))
          (972 (cl:go pc-972))
          (973 (cl:go pc-973))
          (974 (cl:go pc-974))
          (975 (cl:go pc-975))
          (976 (cl:go pc-976))
          (977 (cl:go pc-977))
          (978 (cl:go pc-978))
          (979 (cl:go pc-979))
          (980 (cl:go pc-980))
          (981 (cl:go pc-981))
          (982 (cl:go pc-982))
          (983 (cl:go pc-983))
          (984 (cl:go pc-984))
          (985 (cl:go pc-985))
          (986 (cl:go pc-986))
          (987 (cl:go pc-987))
          (988 (cl:go pc-988))
          (989 (cl:go pc-989))
          (990 (cl:go pc-990))
          (991 (cl:go pc-991))
          (992 (cl:go pc-992))
          (993 (cl:go pc-993))
          (994 (cl:go pc-994))
          (995 (cl:go pc-995))
          (996 (cl:go pc-996))
          (997 (cl:go pc-997))
          (998 (cl:go pc-998))
          (999 (cl:go pc-999))
          (1000 (cl:go pc-1000))
          (1001 (cl:go pc-1001))
          (1002 (cl:go pc-1002))
          (1003 (cl:go pc-1003))
          (1004 (cl:go pc-1004))
          (1005 (cl:go pc-1005))
          (1006 (cl:go pc-1006))
          (1007 (cl:go pc-1007))
          (1008 (cl:go pc-1008))
          (1009 (cl:go pc-1009))
          (1010 (cl:go pc-1010))
          (1011 (cl:go pc-1011))
          (1012 (cl:go pc-1012))
          (1013 (cl:go pc-1013))
          (1014 (cl:go pc-1014))
          (1015 (cl:go pc-1015))
          (1016 (cl:go pc-1016))
          (1017 (cl:go pc-1017))
          (1018 (cl:go pc-1018))
          (1019 (cl:go pc-1019))
          (1020 (cl:go pc-1020))
          (1021 (cl:go pc-1021))
          (1022 (cl:go pc-1022))
          (1023 (cl:go pc-1023))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 1280)
        (cl:case pc
          (1024 (cl:go pc-1024))
          (1025 (cl:go pc-1025))
          (1026 (cl:go pc-1026))
          (1027 (cl:go pc-1027))
          (1028 (cl:go pc-1028))
          (1029 (cl:go pc-1029))
          (1030 (cl:go pc-1030))
          (1031 (cl:go pc-1031))
          (1032 (cl:go pc-1032))
          (1033 (cl:go pc-1033))
          (1034 (cl:go pc-1034))
          (1035 (cl:go pc-1035))
          (1036 (cl:go pc-1036))
          (1037 (cl:go pc-1037))
          (1038 (cl:go pc-1038))
          (1039 (cl:go pc-1039))
          (1040 (cl:go pc-1040))
          (1041 (cl:go pc-1041))
          (1042 (cl:go pc-1042))
          (1043 (cl:go pc-1043))
          (1044 (cl:go pc-1044))
          (1045 (cl:go pc-1045))
          (1046 (cl:go pc-1046))
          (1047 (cl:go pc-1047))
          (1048 (cl:go pc-1048))
          (1049 (cl:go pc-1049))
          (1050 (cl:go pc-1050))
          (1051 (cl:go pc-1051))
          (1052 (cl:go pc-1052))
          (1053 (cl:go pc-1053))
          (1054 (cl:go pc-1054))
          (1055 (cl:go pc-1055))
          (1056 (cl:go pc-1056))
          (1057 (cl:go pc-1057))
          (1058 (cl:go pc-1058))
          (1059 (cl:go pc-1059))
          (1060 (cl:go pc-1060))
          (1061 (cl:go pc-1061))
          (1062 (cl:go pc-1062))
          (1063 (cl:go pc-1063))
          (1064 (cl:go pc-1064))
          (1065 (cl:go pc-1065))
          (1066 (cl:go pc-1066))
          (1067 (cl:go pc-1067))
          (1068 (cl:go pc-1068))
          (1069 (cl:go pc-1069))
          (1070 (cl:go pc-1070))
          (1071 (cl:go pc-1071))
          (1072 (cl:go pc-1072))
          (1073 (cl:go pc-1073))
          (1074 (cl:go pc-1074))
          (1075 (cl:go pc-1075))
          (1076 (cl:go pc-1076))
          (1077 (cl:go pc-1077))
          (1078 (cl:go pc-1078))
          (1079 (cl:go pc-1079))
          (1080 (cl:go pc-1080))
          (1081 (cl:go pc-1081))
          (1082 (cl:go pc-1082))
          (1083 (cl:go pc-1083))
          (1084 (cl:go pc-1084))
          (1085 (cl:go pc-1085))
          (1086 (cl:go pc-1086))
          (1087 (cl:go pc-1087))
          (1088 (cl:go pc-1088))
          (1089 (cl:go pc-1089))
          (1090 (cl:go pc-1090))
          (1091 (cl:go pc-1091))
          (1092 (cl:go pc-1092))
          (1093 (cl:go pc-1093))
          (1094 (cl:go pc-1094))
          (1095 (cl:go pc-1095))
          (1096 (cl:go pc-1096))
          (1097 (cl:go pc-1097))
          (1098 (cl:go pc-1098))
          (1099 (cl:go pc-1099))
          (1100 (cl:go pc-1100))
          (1101 (cl:go pc-1101))
          (1102 (cl:go pc-1102))
          (1103 (cl:go pc-1103))
          (1104 (cl:go pc-1104))
          (1105 (cl:go pc-1105))
          (1106 (cl:go pc-1106))
          (1107 (cl:go pc-1107))
          (1108 (cl:go pc-1108))
          (1109 (cl:go pc-1109))
          (1110 (cl:go pc-1110))
          (1111 (cl:go pc-1111))
          (1112 (cl:go pc-1112))
          (1113 (cl:go pc-1113))
          (1114 (cl:go pc-1114))
          (1115 (cl:go pc-1115))
          (1116 (cl:go pc-1116))
          (1117 (cl:go pc-1117))
          (1118 (cl:go pc-1118))
          (1119 (cl:go pc-1119))
          (1120 (cl:go pc-1120))
          (1121 (cl:go pc-1121))
          (1122 (cl:go pc-1122))
          (1123 (cl:go pc-1123))
          (1124 (cl:go pc-1124))
          (1125 (cl:go pc-1125))
          (1126 (cl:go pc-1126))
          (1127 (cl:go pc-1127))
          (1128 (cl:go pc-1128))
          (1129 (cl:go pc-1129))
          (1130 (cl:go pc-1130))
          (1131 (cl:go pc-1131))
          (1132 (cl:go pc-1132))
          (1133 (cl:go pc-1133))
          (1134 (cl:go pc-1134))
          (1135 (cl:go pc-1135))
          (1136 (cl:go pc-1136))
          (1137 (cl:go pc-1137))
          (1138 (cl:go pc-1138))
          (1139 (cl:go pc-1139))
          (1140 (cl:go pc-1140))
          (1141 (cl:go pc-1141))
          (1142 (cl:go pc-1142))
          (1143 (cl:go pc-1143))
          (1144 (cl:go pc-1144))
          (1145 (cl:go pc-1145))
          (1146 (cl:go pc-1146))
          (1147 (cl:go pc-1147))
          (1148 (cl:go pc-1148))
          (1149 (cl:go pc-1149))
          (1150 (cl:go pc-1150))
          (1151 (cl:go pc-1151))
          (1152 (cl:go pc-1152))
          (1153 (cl:go pc-1153))
          (1154 (cl:go pc-1154))
          (1155 (cl:go pc-1155))
          (1156 (cl:go pc-1156))
          (1157 (cl:go pc-1157))
          (1158 (cl:go pc-1158))
          (1159 (cl:go pc-1159))
          (1160 (cl:go pc-1160))
          (1161 (cl:go pc-1161))
          (1162 (cl:go pc-1162))
          (1163 (cl:go pc-1163))
          (1164 (cl:go pc-1164))
          (1165 (cl:go pc-1165))
          (1166 (cl:go pc-1166))
          (1167 (cl:go pc-1167))
          (1168 (cl:go pc-1168))
          (1169 (cl:go pc-1169))
          (1170 (cl:go pc-1170))
          (1171 (cl:go pc-1171))
          (1172 (cl:go pc-1172))
          (1173 (cl:go pc-1173))
          (1174 (cl:go pc-1174))
          (1175 (cl:go pc-1175))
          (1176 (cl:go pc-1176))
          (1177 (cl:go pc-1177))
          (1178 (cl:go pc-1178))
          (1179 (cl:go pc-1179))
          (1180 (cl:go pc-1180))
          (1181 (cl:go pc-1181))
          (1182 (cl:go pc-1182))
          (1183 (cl:go pc-1183))
          (1184 (cl:go pc-1184))
          (1185 (cl:go pc-1185))
          (1186 (cl:go pc-1186))
          (1187 (cl:go pc-1187))
          (1188 (cl:go pc-1188))
          (1189 (cl:go pc-1189))
          (1190 (cl:go pc-1190))
          (1191 (cl:go pc-1191))
          (1192 (cl:go pc-1192))
          (1193 (cl:go pc-1193))
          (1194 (cl:go pc-1194))
          (1195 (cl:go pc-1195))
          (1196 (cl:go pc-1196))
          (1197 (cl:go pc-1197))
          (1198 (cl:go pc-1198))
          (1199 (cl:go pc-1199))
          (1200 (cl:go pc-1200))
          (1201 (cl:go pc-1201))
          (1202 (cl:go pc-1202))
          (1203 (cl:go pc-1203))
          (1204 (cl:go pc-1204))
          (1205 (cl:go pc-1205))
          (1206 (cl:go pc-1206))
          (1207 (cl:go pc-1207))
          (1208 (cl:go pc-1208))
          (1209 (cl:go pc-1209))
          (1210 (cl:go pc-1210))
          (1211 (cl:go pc-1211))
          (1212 (cl:go pc-1212))
          (1213 (cl:go pc-1213))
          (1214 (cl:go pc-1214))
          (1215 (cl:go pc-1215))
          (1216 (cl:go pc-1216))
          (1217 (cl:go pc-1217))
          (1218 (cl:go pc-1218))
          (1219 (cl:go pc-1219))
          (1220 (cl:go pc-1220))
          (1221 (cl:go pc-1221))
          (1222 (cl:go pc-1222))
          (1223 (cl:go pc-1223))
          (1224 (cl:go pc-1224))
          (1225 (cl:go pc-1225))
          (1226 (cl:go pc-1226))
          (1227 (cl:go pc-1227))
          (1228 (cl:go pc-1228))
          (1229 (cl:go pc-1229))
          (1230 (cl:go pc-1230))
          (1231 (cl:go pc-1231))
          (1232 (cl:go pc-1232))
          (1233 (cl:go pc-1233))
          (1234 (cl:go pc-1234))
          (1235 (cl:go pc-1235))
          (1236 (cl:go pc-1236))
          (1237 (cl:go pc-1237))
          (1238 (cl:go pc-1238))
          (1239 (cl:go pc-1239))
          (1240 (cl:go pc-1240))
          (1241 (cl:go pc-1241))
          (1242 (cl:go pc-1242))
          (1243 (cl:go pc-1243))
          (1244 (cl:go pc-1244))
          (1245 (cl:go pc-1245))
          (1246 (cl:go pc-1246))
          (1247 (cl:go pc-1247))
          (1248 (cl:go pc-1248))
          (1249 (cl:go pc-1249))
          (1250 (cl:go pc-1250))
          (1251 (cl:go pc-1251))
          (1252 (cl:go pc-1252))
          (1253 (cl:go pc-1253))
          (1254 (cl:go pc-1254))
          (1255 (cl:go pc-1255))
          (1256 (cl:go pc-1256))
          (1257 (cl:go pc-1257))
          (1258 (cl:go pc-1258))
          (1259 (cl:go pc-1259))
          (1260 (cl:go pc-1260))
          (1261 (cl:go pc-1261))
          (1262 (cl:go pc-1262))
          (1263 (cl:go pc-1263))
          (1264 (cl:go pc-1264))
          (1265 (cl:go pc-1265))
          (1266 (cl:go pc-1266))
          (1267 (cl:go pc-1267))
          (1268 (cl:go pc-1268))
          (1269 (cl:go pc-1269))
          (1270 (cl:go pc-1270))
          (1271 (cl:go pc-1271))
          (1272 (cl:go pc-1272))
          (1273 (cl:go pc-1273))
          (1274 (cl:go pc-1274))
          (1275 (cl:go pc-1275))
          (1276 (cl:go pc-1276))
          (1277 (cl:go pc-1277))
          (1278 (cl:go pc-1278))
          (1279 (cl:go pc-1279))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 1536)
        (cl:case pc
          (1280 (cl:go pc-1280))
          (1281 (cl:go pc-1281))
          (1282 (cl:go pc-1282))
          (1283 (cl:go pc-1283))
          (1284 (cl:go pc-1284))
          (1285 (cl:go pc-1285))
          (1286 (cl:go pc-1286))
          (1287 (cl:go pc-1287))
          (1288 (cl:go pc-1288))
          (1289 (cl:go pc-1289))
          (1290 (cl:go pc-1290))
          (1291 (cl:go pc-1291))
          (1292 (cl:go pc-1292))
          (1293 (cl:go pc-1293))
          (1294 (cl:go pc-1294))
          (1295 (cl:go pc-1295))
          (1296 (cl:go pc-1296))
          (1297 (cl:go pc-1297))
          (1298 (cl:go pc-1298))
          (1299 (cl:go pc-1299))
          (1300 (cl:go pc-1300))
          (1301 (cl:go pc-1301))
          (1302 (cl:go pc-1302))
          (1303 (cl:go pc-1303))
          (1304 (cl:go pc-1304))
          (1305 (cl:go pc-1305))
          (1306 (cl:go pc-1306))
          (1307 (cl:go pc-1307))
          (1308 (cl:go pc-1308))
          (1309 (cl:go pc-1309))
          (1310 (cl:go pc-1310))
          (1311 (cl:go pc-1311))
          (1312 (cl:go pc-1312))
          (1313 (cl:go pc-1313))
          (1314 (cl:go pc-1314))
          (1315 (cl:go pc-1315))
          (1316 (cl:go pc-1316))
          (1317 (cl:go pc-1317))
          (1318 (cl:go pc-1318))
          (1319 (cl:go pc-1319))
          (1320 (cl:go pc-1320))
          (1321 (cl:go pc-1321))
          (1322 (cl:go pc-1322))
          (1323 (cl:go pc-1323))
          (1324 (cl:go pc-1324))
          (1325 (cl:go pc-1325))
          (1326 (cl:go pc-1326))
          (1327 (cl:go pc-1327))
          (1328 (cl:go pc-1328))
          (1329 (cl:go pc-1329))
          (1330 (cl:go pc-1330))
          (1331 (cl:go pc-1331))
          (1332 (cl:go pc-1332))
          (1333 (cl:go pc-1333))
          (1334 (cl:go pc-1334))
          (1335 (cl:go pc-1335))
          (1336 (cl:go pc-1336))
          (1337 (cl:go pc-1337))
          (1338 (cl:go pc-1338))
          (1339 (cl:go pc-1339))
          (1340 (cl:go pc-1340))
          (1341 (cl:go pc-1341))
          (1342 (cl:go pc-1342))
          (1343 (cl:go pc-1343))
          (1344 (cl:go pc-1344))
          (1345 (cl:go pc-1345))
          (1346 (cl:go pc-1346))
          (1347 (cl:go pc-1347))
          (1348 (cl:go pc-1348))
          (1349 (cl:go pc-1349))
          (1350 (cl:go pc-1350))
          (1351 (cl:go pc-1351))
          (1352 (cl:go pc-1352))
          (1353 (cl:go pc-1353))
          (1354 (cl:go pc-1354))
          (1355 (cl:go pc-1355))
          (1356 (cl:go pc-1356))
          (1357 (cl:go pc-1357))
          (1358 (cl:go pc-1358))
          (1359 (cl:go pc-1359))
          (1360 (cl:go pc-1360))
          (1361 (cl:go pc-1361))
          (1362 (cl:go pc-1362))
          (1363 (cl:go pc-1363))
          (1364 (cl:go pc-1364))
          (1365 (cl:go pc-1365))
          (1366 (cl:go pc-1366))
          (1367 (cl:go pc-1367))
          (1368 (cl:go pc-1368))
          (1369 (cl:go pc-1369))
          (1370 (cl:go pc-1370))
          (1371 (cl:go pc-1371))
          (1372 (cl:go pc-1372))
          (1373 (cl:go pc-1373))
          (1374 (cl:go pc-1374))
          (1375 (cl:go pc-1375))
          (1376 (cl:go pc-1376))
          (1377 (cl:go pc-1377))
          (1378 (cl:go pc-1378))
          (1379 (cl:go pc-1379))
          (1380 (cl:go pc-1380))
          (1381 (cl:go pc-1381))
          (1382 (cl:go pc-1382))
          (1383 (cl:go pc-1383))
          (1384 (cl:go pc-1384))
          (1385 (cl:go pc-1385))
          (1386 (cl:go pc-1386))
          (1387 (cl:go pc-1387))
          (1388 (cl:go pc-1388))
          (1389 (cl:go pc-1389))
          (1390 (cl:go pc-1390))
          (1391 (cl:go pc-1391))
          (1392 (cl:go pc-1392))
          (1393 (cl:go pc-1393))
          (1394 (cl:go pc-1394))
          (1395 (cl:go pc-1395))
          (1396 (cl:go pc-1396))
          (1397 (cl:go pc-1397))
          (1398 (cl:go pc-1398))
          (1399 (cl:go pc-1399))
          (1400 (cl:go pc-1400))
          (1401 (cl:go pc-1401))
          (1402 (cl:go pc-1402))
          (1403 (cl:go pc-1403))
          (1404 (cl:go pc-1404))
          (1405 (cl:go pc-1405))
          (1406 (cl:go pc-1406))
          (1407 (cl:go pc-1407))
          (1408 (cl:go pc-1408))
          (1409 (cl:go pc-1409))
          (1410 (cl:go pc-1410))
          (1411 (cl:go pc-1411))
          (1412 (cl:go pc-1412))
          (1413 (cl:go pc-1413))
          (1414 (cl:go pc-1414))
          (1415 (cl:go pc-1415))
          (1416 (cl:go pc-1416))
          (1417 (cl:go pc-1417))
          (1418 (cl:go pc-1418))
          (1419 (cl:go pc-1419))
          (1420 (cl:go pc-1420))
          (1421 (cl:go pc-1421))
          (1422 (cl:go pc-1422))
          (1423 (cl:go pc-1423))
          (1424 (cl:go pc-1424))
          (1425 (cl:go pc-1425))
          (1426 (cl:go pc-1426))
          (1427 (cl:go pc-1427))
          (1428 (cl:go pc-1428))
          (1429 (cl:go pc-1429))
          (1430 (cl:go pc-1430))
          (1431 (cl:go pc-1431))
          (1432 (cl:go pc-1432))
          (1433 (cl:go pc-1433))
          (1434 (cl:go pc-1434))
          (1435 (cl:go pc-1435))
          (1436 (cl:go pc-1436))
          (1437 (cl:go pc-1437))
          (1438 (cl:go pc-1438))
          (1439 (cl:go pc-1439))
          (1440 (cl:go pc-1440))
          (1441 (cl:go pc-1441))
          (1442 (cl:go pc-1442))
          (1443 (cl:go pc-1443))
          (1444 (cl:go pc-1444))
          (1445 (cl:go pc-1445))
          (1446 (cl:go pc-1446))
          (1447 (cl:go pc-1447))
          (1448 (cl:go pc-1448))
          (1449 (cl:go pc-1449))
          (1450 (cl:go pc-1450))
          (1451 (cl:go pc-1451))
          (1452 (cl:go pc-1452))
          (1453 (cl:go pc-1453))
          (1454 (cl:go pc-1454))
          (1455 (cl:go pc-1455))
          (1456 (cl:go pc-1456))
          (1457 (cl:go pc-1457))
          (1458 (cl:go pc-1458))
          (1459 (cl:go pc-1459))
          (1460 (cl:go pc-1460))
          (1461 (cl:go pc-1461))
          (1462 (cl:go pc-1462))
          (1463 (cl:go pc-1463))
          (1464 (cl:go pc-1464))
          (1465 (cl:go pc-1465))
          (1466 (cl:go pc-1466))
          (1467 (cl:go pc-1467))
          (1468 (cl:go pc-1468))
          (1469 (cl:go pc-1469))
          (1470 (cl:go pc-1470))
          (1471 (cl:go pc-1471))
          (1472 (cl:go pc-1472))
          (1473 (cl:go pc-1473))
          (1474 (cl:go pc-1474))
          (1475 (cl:go pc-1475))
          (1476 (cl:go pc-1476))
          (1477 (cl:go pc-1477))
          (1478 (cl:go pc-1478))
          (1479 (cl:go pc-1479))
          (1480 (cl:go pc-1480))
          (1481 (cl:go pc-1481))
          (1482 (cl:go pc-1482))
          (1483 (cl:go pc-1483))
          (1484 (cl:go pc-1484))
          (1485 (cl:go pc-1485))
          (1486 (cl:go pc-1486))
          (1487 (cl:go pc-1487))
          (1488 (cl:go pc-1488))
          (1489 (cl:go pc-1489))
          (1490 (cl:go pc-1490))
          (1491 (cl:go pc-1491))
          (1492 (cl:go pc-1492))
          (1493 (cl:go pc-1493))
          (1494 (cl:go pc-1494))
          (1495 (cl:go pc-1495))
          (1496 (cl:go pc-1496))
          (1497 (cl:go pc-1497))
          (1498 (cl:go pc-1498))
          (1499 (cl:go pc-1499))
          (1500 (cl:go pc-1500))
          (1501 (cl:go pc-1501))
          (1502 (cl:go pc-1502))
          (1503 (cl:go pc-1503))
          (1504 (cl:go pc-1504))
          (1505 (cl:go pc-1505))
          (1506 (cl:go pc-1506))
          (1507 (cl:go pc-1507))
          (1508 (cl:go pc-1508))
          (1509 (cl:go pc-1509))
          (1510 (cl:go pc-1510))
          (1511 (cl:go pc-1511))
          (1512 (cl:go pc-1512))
          (1513 (cl:go pc-1513))
          (1514 (cl:go pc-1514))
          (1515 (cl:go pc-1515))
          (1516 (cl:go pc-1516))
          (1517 (cl:go pc-1517))
          (1518 (cl:go pc-1518))
          (1519 (cl:go pc-1519))
          (1520 (cl:go pc-1520))
          (1521 (cl:go pc-1521))
          (1522 (cl:go pc-1522))
          (1523 (cl:go pc-1523))
          (1524 (cl:go pc-1524))
          (1525 (cl:go pc-1525))
          (1526 (cl:go pc-1526))
          (1527 (cl:go pc-1527))
          (1528 (cl:go pc-1528))
          (1529 (cl:go pc-1529))
          (1530 (cl:go pc-1530))
          (1531 (cl:go pc-1531))
          (1532 (cl:go pc-1532))
          (1533 (cl:go pc-1533))
          (1534 (cl:go pc-1534))
          (1535 (cl:go pc-1535))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 1792)
        (cl:case pc
          (1536 (cl:go pc-1536))
          (1537 (cl:go pc-1537))
          (1538 (cl:go pc-1538))
          (1539 (cl:go pc-1539))
          (1540 (cl:go pc-1540))
          (1541 (cl:go pc-1541))
          (1542 (cl:go pc-1542))
          (1543 (cl:go pc-1543))
          (1544 (cl:go pc-1544))
          (1545 (cl:go pc-1545))
          (1546 (cl:go pc-1546))
          (1547 (cl:go pc-1547))
          (1548 (cl:go pc-1548))
          (1549 (cl:go pc-1549))
          (1550 (cl:go pc-1550))
          (1551 (cl:go pc-1551))
          (1552 (cl:go pc-1552))
          (1553 (cl:go pc-1553))
          (1554 (cl:go pc-1554))
          (1555 (cl:go pc-1555))
          (1556 (cl:go pc-1556))
          (1557 (cl:go pc-1557))
          (1558 (cl:go pc-1558))
          (1559 (cl:go pc-1559))
          (1560 (cl:go pc-1560))
          (1561 (cl:go pc-1561))
          (1562 (cl:go pc-1562))
          (1563 (cl:go pc-1563))
          (1564 (cl:go pc-1564))
          (1565 (cl:go pc-1565))
          (1566 (cl:go pc-1566))
          (1567 (cl:go pc-1567))
          (1568 (cl:go pc-1568))
          (1569 (cl:go pc-1569))
          (1570 (cl:go pc-1570))
          (1571 (cl:go pc-1571))
          (1572 (cl:go pc-1572))
          (1573 (cl:go pc-1573))
          (1574 (cl:go pc-1574))
          (1575 (cl:go pc-1575))
          (1576 (cl:go pc-1576))
          (1577 (cl:go pc-1577))
          (1578 (cl:go pc-1578))
          (1579 (cl:go pc-1579))
          (1580 (cl:go pc-1580))
          (1581 (cl:go pc-1581))
          (1582 (cl:go pc-1582))
          (1583 (cl:go pc-1583))
          (1584 (cl:go pc-1584))
          (1585 (cl:go pc-1585))
          (1586 (cl:go pc-1586))
          (1587 (cl:go pc-1587))
          (1588 (cl:go pc-1588))
          (1589 (cl:go pc-1589))
          (1590 (cl:go pc-1590))
          (1591 (cl:go pc-1591))
          (1592 (cl:go pc-1592))
          (1593 (cl:go pc-1593))
          (1594 (cl:go pc-1594))
          (1595 (cl:go pc-1595))
          (1596 (cl:go pc-1596))
          (1597 (cl:go pc-1597))
          (1598 (cl:go pc-1598))
          (1599 (cl:go pc-1599))
          (1600 (cl:go pc-1600))
          (1601 (cl:go pc-1601))
          (1602 (cl:go pc-1602))
          (1603 (cl:go pc-1603))
          (1604 (cl:go pc-1604))
          (1605 (cl:go pc-1605))
          (1606 (cl:go pc-1606))
          (1607 (cl:go pc-1607))
          (1608 (cl:go pc-1608))
          (1609 (cl:go pc-1609))
          (1610 (cl:go pc-1610))
          (1611 (cl:go pc-1611))
          (1612 (cl:go pc-1612))
          (1613 (cl:go pc-1613))
          (1614 (cl:go pc-1614))
          (1615 (cl:go pc-1615))
          (1616 (cl:go pc-1616))
          (1617 (cl:go pc-1617))
          (1618 (cl:go pc-1618))
          (1619 (cl:go pc-1619))
          (1620 (cl:go pc-1620))
          (1621 (cl:go pc-1621))
          (1622 (cl:go pc-1622))
          (1623 (cl:go pc-1623))
          (1624 (cl:go pc-1624))
          (1625 (cl:go pc-1625))
          (1626 (cl:go pc-1626))
          (1627 (cl:go pc-1627))
          (1628 (cl:go pc-1628))
          (1629 (cl:go pc-1629))
          (1630 (cl:go pc-1630))
          (1631 (cl:go pc-1631))
          (1632 (cl:go pc-1632))
          (1633 (cl:go pc-1633))
          (1634 (cl:go pc-1634))
          (1635 (cl:go pc-1635))
          (1636 (cl:go pc-1636))
          (1637 (cl:go pc-1637))
          (1638 (cl:go pc-1638))
          (1639 (cl:go pc-1639))
          (1640 (cl:go pc-1640))
          (1641 (cl:go pc-1641))
          (1642 (cl:go pc-1642))
          (1643 (cl:go pc-1643))
          (1644 (cl:go pc-1644))
          (1645 (cl:go pc-1645))
          (1646 (cl:go pc-1646))
          (1647 (cl:go pc-1647))
          (1648 (cl:go pc-1648))
          (1649 (cl:go pc-1649))
          (1650 (cl:go pc-1650))
          (1651 (cl:go pc-1651))
          (1652 (cl:go pc-1652))
          (1653 (cl:go pc-1653))
          (1654 (cl:go pc-1654))
          (1655 (cl:go pc-1655))
          (1656 (cl:go pc-1656))
          (1657 (cl:go pc-1657))
          (1658 (cl:go pc-1658))
          (1659 (cl:go pc-1659))
          (1660 (cl:go pc-1660))
          (1661 (cl:go pc-1661))
          (1662 (cl:go pc-1662))
          (1663 (cl:go pc-1663))
          (1664 (cl:go pc-1664))
          (1665 (cl:go pc-1665))
          (1666 (cl:go pc-1666))
          (1667 (cl:go pc-1667))
          (1668 (cl:go pc-1668))
          (1669 (cl:go pc-1669))
          (1670 (cl:go pc-1670))
          (1671 (cl:go pc-1671))
          (1672 (cl:go pc-1672))
          (1673 (cl:go pc-1673))
          (1674 (cl:go pc-1674))
          (1675 (cl:go pc-1675))
          (1676 (cl:go pc-1676))
          (1677 (cl:go pc-1677))
          (1678 (cl:go pc-1678))
          (1679 (cl:go pc-1679))
          (1680 (cl:go pc-1680))
          (1681 (cl:go pc-1681))
          (1682 (cl:go pc-1682))
          (1683 (cl:go pc-1683))
          (1684 (cl:go pc-1684))
          (1685 (cl:go pc-1685))
          (1686 (cl:go pc-1686))
          (1687 (cl:go pc-1687))
          (1688 (cl:go pc-1688))
          (1689 (cl:go pc-1689))
          (1690 (cl:go pc-1690))
          (1691 (cl:go pc-1691))
          (1692 (cl:go pc-1692))
          (1693 (cl:go pc-1693))
          (1694 (cl:go pc-1694))
          (1695 (cl:go pc-1695))
          (1696 (cl:go pc-1696))
          (1697 (cl:go pc-1697))
          (1698 (cl:go pc-1698))
          (1699 (cl:go pc-1699))
          (1700 (cl:go pc-1700))
          (1701 (cl:go pc-1701))
          (1702 (cl:go pc-1702))
          (1703 (cl:go pc-1703))
          (1704 (cl:go pc-1704))
          (1705 (cl:go pc-1705))
          (1706 (cl:go pc-1706))
          (1707 (cl:go pc-1707))
          (1708 (cl:go pc-1708))
          (1709 (cl:go pc-1709))
          (1710 (cl:go pc-1710))
          (1711 (cl:go pc-1711))
          (1712 (cl:go pc-1712))
          (1713 (cl:go pc-1713))
          (1714 (cl:go pc-1714))
          (1715 (cl:go pc-1715))
          (1716 (cl:go pc-1716))
          (1717 (cl:go pc-1717))
          (1718 (cl:go pc-1718))
          (1719 (cl:go pc-1719))
          (1720 (cl:go pc-1720))
          (1721 (cl:go pc-1721))
          (1722 (cl:go pc-1722))
          (1723 (cl:go pc-1723))
          (1724 (cl:go pc-1724))
          (1725 (cl:go pc-1725))
          (1726 (cl:go pc-1726))
          (1727 (cl:go pc-1727))
          (1728 (cl:go pc-1728))
          (1729 (cl:go pc-1729))
          (1730 (cl:go pc-1730))
          (1731 (cl:go pc-1731))
          (1732 (cl:go pc-1732))
          (1733 (cl:go pc-1733))
          (1734 (cl:go pc-1734))
          (1735 (cl:go pc-1735))
          (1736 (cl:go pc-1736))
          (1737 (cl:go pc-1737))
          (1738 (cl:go pc-1738))
          (1739 (cl:go pc-1739))
          (1740 (cl:go pc-1740))
          (1741 (cl:go pc-1741))
          (1742 (cl:go pc-1742))
          (1743 (cl:go pc-1743))
          (1744 (cl:go pc-1744))
          (1745 (cl:go pc-1745))
          (1746 (cl:go pc-1746))
          (1747 (cl:go pc-1747))
          (1748 (cl:go pc-1748))
          (1749 (cl:go pc-1749))
          (1750 (cl:go pc-1750))
          (1751 (cl:go pc-1751))
          (1752 (cl:go pc-1752))
          (1753 (cl:go pc-1753))
          (1754 (cl:go pc-1754))
          (1755 (cl:go pc-1755))
          (1756 (cl:go pc-1756))
          (1757 (cl:go pc-1757))
          (1758 (cl:go pc-1758))
          (1759 (cl:go pc-1759))
          (1760 (cl:go pc-1760))
          (1761 (cl:go pc-1761))
          (1762 (cl:go pc-1762))
          (1763 (cl:go pc-1763))
          (1764 (cl:go pc-1764))
          (1765 (cl:go pc-1765))
          (1766 (cl:go pc-1766))
          (1767 (cl:go pc-1767))
          (1768 (cl:go pc-1768))
          (1769 (cl:go pc-1769))
          (1770 (cl:go pc-1770))
          (1771 (cl:go pc-1771))
          (1772 (cl:go pc-1772))
          (1773 (cl:go pc-1773))
          (1774 (cl:go pc-1774))
          (1775 (cl:go pc-1775))
          (1776 (cl:go pc-1776))
          (1777 (cl:go pc-1777))
          (1778 (cl:go pc-1778))
          (1779 (cl:go pc-1779))
          (1780 (cl:go pc-1780))
          (1781 (cl:go pc-1781))
          (1782 (cl:go pc-1782))
          (1783 (cl:go pc-1783))
          (1784 (cl:go pc-1784))
          (1785 (cl:go pc-1785))
          (1786 (cl:go pc-1786))
          (1787 (cl:go pc-1787))
          (1788 (cl:go pc-1788))
          (1789 (cl:go pc-1789))
          (1790 (cl:go pc-1790))
          (1791 (cl:go pc-1791))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 2048)
        (cl:case pc
          (1792 (cl:go pc-1792))
          (1793 (cl:go pc-1793))
          (1794 (cl:go pc-1794))
          (1795 (cl:go pc-1795))
          (1796 (cl:go pc-1796))
          (1797 (cl:go pc-1797))
          (1798 (cl:go pc-1798))
          (1799 (cl:go pc-1799))
          (1800 (cl:go pc-1800))
          (1801 (cl:go pc-1801))
          (1802 (cl:go pc-1802))
          (1803 (cl:go pc-1803))
          (1804 (cl:go pc-1804))
          (1805 (cl:go pc-1805))
          (1806 (cl:go pc-1806))
          (1807 (cl:go pc-1807))
          (1808 (cl:go pc-1808))
          (1809 (cl:go pc-1809))
          (1810 (cl:go pc-1810))
          (1811 (cl:go pc-1811))
          (1812 (cl:go pc-1812))
          (1813 (cl:go pc-1813))
          (1814 (cl:go pc-1814))
          (1815 (cl:go pc-1815))
          (1816 (cl:go pc-1816))
          (1817 (cl:go pc-1817))
          (1818 (cl:go pc-1818))
          (1819 (cl:go pc-1819))
          (1820 (cl:go pc-1820))
          (1821 (cl:go pc-1821))
          (1822 (cl:go pc-1822))
          (1823 (cl:go pc-1823))
          (1824 (cl:go pc-1824))
          (1825 (cl:go pc-1825))
          (1826 (cl:go pc-1826))
          (1827 (cl:go pc-1827))
          (1828 (cl:go pc-1828))
          (1829 (cl:go pc-1829))
          (1830 (cl:go pc-1830))
          (1831 (cl:go pc-1831))
          (1832 (cl:go pc-1832))
          (1833 (cl:go pc-1833))
          (1834 (cl:go pc-1834))
          (1835 (cl:go pc-1835))
          (1836 (cl:go pc-1836))
          (1837 (cl:go pc-1837))
          (1838 (cl:go pc-1838))
          (1839 (cl:go pc-1839))
          (1840 (cl:go pc-1840))
          (1841 (cl:go pc-1841))
          (1842 (cl:go pc-1842))
          (1843 (cl:go pc-1843))
          (1844 (cl:go pc-1844))
          (1845 (cl:go pc-1845))
          (1846 (cl:go pc-1846))
          (1847 (cl:go pc-1847))
          (1848 (cl:go pc-1848))
          (1849 (cl:go pc-1849))
          (1850 (cl:go pc-1850))
          (1851 (cl:go pc-1851))
          (1852 (cl:go pc-1852))
          (1853 (cl:go pc-1853))
          (1854 (cl:go pc-1854))
          (1855 (cl:go pc-1855))
          (1856 (cl:go pc-1856))
          (1857 (cl:go pc-1857))
          (1858 (cl:go pc-1858))
          (1859 (cl:go pc-1859))
          (1860 (cl:go pc-1860))
          (1861 (cl:go pc-1861))
          (1862 (cl:go pc-1862))
          (1863 (cl:go pc-1863))
          (1864 (cl:go pc-1864))
          (1865 (cl:go pc-1865))
          (1866 (cl:go pc-1866))
          (1867 (cl:go pc-1867))
          (1868 (cl:go pc-1868))
          (1869 (cl:go pc-1869))
          (1870 (cl:go pc-1870))
          (1871 (cl:go pc-1871))
          (1872 (cl:go pc-1872))
          (1873 (cl:go pc-1873))
          (1874 (cl:go pc-1874))
          (1875 (cl:go pc-1875))
          (1876 (cl:go pc-1876))
          (1877 (cl:go pc-1877))
          (1878 (cl:go pc-1878))
          (1879 (cl:go pc-1879))
          (1880 (cl:go pc-1880))
          (1881 (cl:go pc-1881))
          (1882 (cl:go pc-1882))
          (1883 (cl:go pc-1883))
          (1884 (cl:go pc-1884))
          (1885 (cl:go pc-1885))
          (1886 (cl:go pc-1886))
          (1887 (cl:go pc-1887))
          (1888 (cl:go pc-1888))
          (1889 (cl:go pc-1889))
          (1890 (cl:go pc-1890))
          (1891 (cl:go pc-1891))
          (1892 (cl:go pc-1892))
          (1893 (cl:go pc-1893))
          (1894 (cl:go pc-1894))
          (1895 (cl:go pc-1895))
          (1896 (cl:go pc-1896))
          (1897 (cl:go pc-1897))
          (1898 (cl:go pc-1898))
          (1899 (cl:go pc-1899))
          (1900 (cl:go pc-1900))
          (1901 (cl:go pc-1901))
          (1902 (cl:go pc-1902))
          (1903 (cl:go pc-1903))
          (1904 (cl:go pc-1904))
          (1905 (cl:go pc-1905))
          (1906 (cl:go pc-1906))
          (1907 (cl:go pc-1907))
          (1908 (cl:go pc-1908))
          (1909 (cl:go pc-1909))
          (1910 (cl:go pc-1910))
          (1911 (cl:go pc-1911))
          (1912 (cl:go pc-1912))
          (1913 (cl:go pc-1913))
          (1914 (cl:go pc-1914))
          (1915 (cl:go pc-1915))
          (1916 (cl:go pc-1916))
          (1917 (cl:go pc-1917))
          (1918 (cl:go pc-1918))
          (1919 (cl:go pc-1919))
          (1920 (cl:go pc-1920))
          (1921 (cl:go pc-1921))
          (1922 (cl:go pc-1922))
          (1923 (cl:go pc-1923))
          (1924 (cl:go pc-1924))
          (1925 (cl:go pc-1925))
          (1926 (cl:go pc-1926))
          (1927 (cl:go pc-1927))
          (1928 (cl:go pc-1928))
          (1929 (cl:go pc-1929))
          (1930 (cl:go pc-1930))
          (1931 (cl:go pc-1931))
          (1932 (cl:go pc-1932))
          (1933 (cl:go pc-1933))
          (1934 (cl:go pc-1934))
          (1935 (cl:go pc-1935))
          (1936 (cl:go pc-1936))
          (1937 (cl:go pc-1937))
          (1938 (cl:go pc-1938))
          (1939 (cl:go pc-1939))
          (1940 (cl:go pc-1940))
          (1941 (cl:go pc-1941))
          (1942 (cl:go pc-1942))
          (1943 (cl:go pc-1943))
          (1944 (cl:go pc-1944))
          (1945 (cl:go pc-1945))
          (1946 (cl:go pc-1946))
          (1947 (cl:go pc-1947))
          (1948 (cl:go pc-1948))
          (1949 (cl:go pc-1949))
          (1950 (cl:go pc-1950))
          (1951 (cl:go pc-1951))
          (1952 (cl:go pc-1952))
          (1953 (cl:go pc-1953))
          (1954 (cl:go pc-1954))
          (1955 (cl:go pc-1955))
          (1956 (cl:go pc-1956))
          (1957 (cl:go pc-1957))
          (1958 (cl:go pc-1958))
          (1959 (cl:go pc-1959))
          (1960 (cl:go pc-1960))
          (1961 (cl:go pc-1961))
          (1962 (cl:go pc-1962))
          (1963 (cl:go pc-1963))
          (1964 (cl:go pc-1964))
          (1965 (cl:go pc-1965))
          (1966 (cl:go pc-1966))
          (1967 (cl:go pc-1967))
          (1968 (cl:go pc-1968))
          (1969 (cl:go pc-1969))
          (1970 (cl:go pc-1970))
          (1971 (cl:go pc-1971))
          (1972 (cl:go pc-1972))
          (1973 (cl:go pc-1973))
          (1974 (cl:go pc-1974))
          (1975 (cl:go pc-1975))
          (1976 (cl:go pc-1976))
          (1977 (cl:go pc-1977))
          (1978 (cl:go pc-1978))
          (1979 (cl:go pc-1979))
          (1980 (cl:go pc-1980))
          (1981 (cl:go pc-1981))
          (1982 (cl:go pc-1982))
          (1983 (cl:go pc-1983))
          (1984 (cl:go pc-1984))
          (1985 (cl:go pc-1985))
          (1986 (cl:go pc-1986))
          (1987 (cl:go pc-1987))
          (1988 (cl:go pc-1988))
          (1989 (cl:go pc-1989))
          (1990 (cl:go pc-1990))
          (1991 (cl:go pc-1991))
          (1992 (cl:go pc-1992))
          (1993 (cl:go pc-1993))
          (1994 (cl:go pc-1994))
          (1995 (cl:go pc-1995))
          (1996 (cl:go pc-1996))
          (1997 (cl:go pc-1997))
          (1998 (cl:go pc-1998))
          (1999 (cl:go pc-1999))
          (2000 (cl:go pc-2000))
          (2001 (cl:go pc-2001))
          (2002 (cl:go pc-2002))
          (2003 (cl:go pc-2003))
          (2004 (cl:go pc-2004))
          (2005 (cl:go pc-2005))
          (2006 (cl:go pc-2006))
          (2007 (cl:go pc-2007))
          (2008 (cl:go pc-2008))
          (2009 (cl:go pc-2009))
          (2010 (cl:go pc-2010))
          (2011 (cl:go pc-2011))
          (2012 (cl:go pc-2012))
          (2013 (cl:go pc-2013))
          (2014 (cl:go pc-2014))
          (2015 (cl:go pc-2015))
          (2016 (cl:go pc-2016))
          (2017 (cl:go pc-2017))
          (2018 (cl:go pc-2018))
          (2019 (cl:go pc-2019))
          (2020 (cl:go pc-2020))
          (2021 (cl:go pc-2021))
          (2022 (cl:go pc-2022))
          (2023 (cl:go pc-2023))
          (2024 (cl:go pc-2024))
          (2025 (cl:go pc-2025))
          (2026 (cl:go pc-2026))
          (2027 (cl:go pc-2027))
          (2028 (cl:go pc-2028))
          (2029 (cl:go pc-2029))
          (2030 (cl:go pc-2030))
          (2031 (cl:go pc-2031))
          (2032 (cl:go pc-2032))
          (2033 (cl:go pc-2033))
          (2034 (cl:go pc-2034))
          (2035 (cl:go pc-2035))
          (2036 (cl:go pc-2036))
          (2037 (cl:go pc-2037))
          (2038 (cl:go pc-2038))
          (2039 (cl:go pc-2039))
          (2040 (cl:go pc-2040))
          (2041 (cl:go pc-2041))
          (2042 (cl:go pc-2042))
          (2043 (cl:go pc-2043))
          (2044 (cl:go pc-2044))
          (2045 (cl:go pc-2045))
          (2046 (cl:go pc-2046))
          (2047 (cl:go pc-2047))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 2304)
        (cl:case pc
          (2048 (cl:go pc-2048))
          (2049 (cl:go pc-2049))
          (2050 (cl:go pc-2050))
          (2051 (cl:go pc-2051))
          (2052 (cl:go pc-2052))
          (2053 (cl:go pc-2053))
          (2054 (cl:go pc-2054))
          (2055 (cl:go pc-2055))
          (2056 (cl:go pc-2056))
          (2057 (cl:go pc-2057))
          (2058 (cl:go pc-2058))
          (2059 (cl:go pc-2059))
          (2060 (cl:go pc-2060))
          (2061 (cl:go pc-2061))
          (2062 (cl:go pc-2062))
          (2063 (cl:go pc-2063))
          (2064 (cl:go pc-2064))
          (2065 (cl:go pc-2065))
          (2066 (cl:go pc-2066))
          (2067 (cl:go pc-2067))
          (2068 (cl:go pc-2068))
          (2069 (cl:go pc-2069))
          (2070 (cl:go pc-2070))
          (2071 (cl:go pc-2071))
          (2072 (cl:go pc-2072))
          (2073 (cl:go pc-2073))
          (2074 (cl:go pc-2074))
          (2075 (cl:go pc-2075))
          (2076 (cl:go pc-2076))
          (2077 (cl:go pc-2077))
          (2078 (cl:go pc-2078))
          (2079 (cl:go pc-2079))
          (2080 (cl:go pc-2080))
          (2081 (cl:go pc-2081))
          (2082 (cl:go pc-2082))
          (2083 (cl:go pc-2083))
          (2084 (cl:go pc-2084))
          (2085 (cl:go pc-2085))
          (2086 (cl:go pc-2086))
          (2087 (cl:go pc-2087))
          (2088 (cl:go pc-2088))
          (2089 (cl:go pc-2089))
          (2090 (cl:go pc-2090))
          (2091 (cl:go pc-2091))
          (2092 (cl:go pc-2092))
          (2093 (cl:go pc-2093))
          (2094 (cl:go pc-2094))
          (2095 (cl:go pc-2095))
          (2096 (cl:go pc-2096))
          (2097 (cl:go pc-2097))
          (2098 (cl:go pc-2098))
          (2099 (cl:go pc-2099))
          (2100 (cl:go pc-2100))
          (2101 (cl:go pc-2101))
          (2102 (cl:go pc-2102))
          (2103 (cl:go pc-2103))
          (2104 (cl:go pc-2104))
          (2105 (cl:go pc-2105))
          (2106 (cl:go pc-2106))
          (2107 (cl:go pc-2107))
          (2108 (cl:go pc-2108))
          (2109 (cl:go pc-2109))
          (2110 (cl:go pc-2110))
          (2111 (cl:go pc-2111))
          (2112 (cl:go pc-2112))
          (2113 (cl:go pc-2113))
          (2114 (cl:go pc-2114))
          (2115 (cl:go pc-2115))
          (2116 (cl:go pc-2116))
          (2117 (cl:go pc-2117))
          (2118 (cl:go pc-2118))
          (2119 (cl:go pc-2119))
          (2120 (cl:go pc-2120))
          (2121 (cl:go pc-2121))
          (2122 (cl:go pc-2122))
          (2123 (cl:go pc-2123))
          (2124 (cl:go pc-2124))
          (2125 (cl:go pc-2125))
          (2126 (cl:go pc-2126))
          (2127 (cl:go pc-2127))
          (2128 (cl:go pc-2128))
          (2129 (cl:go pc-2129))
          (2130 (cl:go pc-2130))
          (2131 (cl:go pc-2131))
          (2132 (cl:go pc-2132))
          (2133 (cl:go pc-2133))
          (2134 (cl:go pc-2134))
          (2135 (cl:go pc-2135))
          (2136 (cl:go pc-2136))
          (2137 (cl:go pc-2137))
          (2138 (cl:go pc-2138))
          (2139 (cl:go pc-2139))
          (2140 (cl:go pc-2140))
          (2141 (cl:go pc-2141))
          (2142 (cl:go pc-2142))
          (2143 (cl:go pc-2143))
          (2144 (cl:go pc-2144))
          (2145 (cl:go pc-2145))
          (2146 (cl:go pc-2146))
          (2147 (cl:go pc-2147))
          (2148 (cl:go pc-2148))
          (2149 (cl:go pc-2149))
          (2150 (cl:go pc-2150))
          (2151 (cl:go pc-2151))
          (2152 (cl:go pc-2152))
          (2153 (cl:go pc-2153))
          (2154 (cl:go pc-2154))
          (2155 (cl:go pc-2155))
          (2156 (cl:go pc-2156))
          (2157 (cl:go pc-2157))
          (2158 (cl:go pc-2158))
          (2159 (cl:go pc-2159))
          (2160 (cl:go pc-2160))
          (2161 (cl:go pc-2161))
          (2162 (cl:go pc-2162))
          (2163 (cl:go pc-2163))
          (2164 (cl:go pc-2164))
          (2165 (cl:go pc-2165))
          (2166 (cl:go pc-2166))
          (2167 (cl:go pc-2167))
          (2168 (cl:go pc-2168))
          (2169 (cl:go pc-2169))
          (2170 (cl:go pc-2170))
          (2171 (cl:go pc-2171))
          (2172 (cl:go pc-2172))
          (2173 (cl:go pc-2173))
          (2174 (cl:go pc-2174))
          (2175 (cl:go pc-2175))
          (2176 (cl:go pc-2176))
          (2177 (cl:go pc-2177))
          (2178 (cl:go pc-2178))
          (2179 (cl:go pc-2179))
          (2180 (cl:go pc-2180))
          (2181 (cl:go pc-2181))
          (2182 (cl:go pc-2182))
          (2183 (cl:go pc-2183))
          (2184 (cl:go pc-2184))
          (2185 (cl:go pc-2185))
          (2186 (cl:go pc-2186))
          (2187 (cl:go pc-2187))
          (2188 (cl:go pc-2188))
          (2189 (cl:go pc-2189))
          (2190 (cl:go pc-2190))
          (2191 (cl:go pc-2191))
          (2192 (cl:go pc-2192))
          (2193 (cl:go pc-2193))
          (2194 (cl:go pc-2194))
          (2195 (cl:go pc-2195))
          (2196 (cl:go pc-2196))
          (2197 (cl:go pc-2197))
          (2198 (cl:go pc-2198))
          (2199 (cl:go pc-2199))
          (2200 (cl:go pc-2200))
          (2201 (cl:go pc-2201))
          (2202 (cl:go pc-2202))
          (2203 (cl:go pc-2203))
          (2204 (cl:go pc-2204))
          (2205 (cl:go pc-2205))
          (2206 (cl:go pc-2206))
          (2207 (cl:go pc-2207))
          (2208 (cl:go pc-2208))
          (2209 (cl:go pc-2209))
          (2210 (cl:go pc-2210))
          (2211 (cl:go pc-2211))
          (2212 (cl:go pc-2212))
          (2213 (cl:go pc-2213))
          (2214 (cl:go pc-2214))
          (2215 (cl:go pc-2215))
          (2216 (cl:go pc-2216))
          (2217 (cl:go pc-2217))
          (2218 (cl:go pc-2218))
          (2219 (cl:go pc-2219))
          (2220 (cl:go pc-2220))
          (2221 (cl:go pc-2221))
          (2222 (cl:go pc-2222))
          (2223 (cl:go pc-2223))
          (2224 (cl:go pc-2224))
          (2225 (cl:go pc-2225))
          (2226 (cl:go pc-2226))
          (2227 (cl:go pc-2227))
          (2228 (cl:go pc-2228))
          (2229 (cl:go pc-2229))
          (2230 (cl:go pc-2230))
          (2231 (cl:go pc-2231))
          (2232 (cl:go pc-2232))
          (2233 (cl:go pc-2233))
          (2234 (cl:go pc-2234))
          (2235 (cl:go pc-2235))
          (2236 (cl:go pc-2236))
          (2237 (cl:go pc-2237))
          (2238 (cl:go pc-2238))
          (2239 (cl:go pc-2239))
          (2240 (cl:go pc-2240))
          (2241 (cl:go pc-2241))
          (2242 (cl:go pc-2242))
          (2243 (cl:go pc-2243))
          (2244 (cl:go pc-2244))
          (2245 (cl:go pc-2245))
          (2246 (cl:go pc-2246))
          (2247 (cl:go pc-2247))
          (2248 (cl:go pc-2248))
          (2249 (cl:go pc-2249))
          (2250 (cl:go pc-2250))
          (2251 (cl:go pc-2251))
          (2252 (cl:go pc-2252))
          (2253 (cl:go pc-2253))
          (2254 (cl:go pc-2254))
          (2255 (cl:go pc-2255))
          (2256 (cl:go pc-2256))
          (2257 (cl:go pc-2257))
          (2258 (cl:go pc-2258))
          (2259 (cl:go pc-2259))
          (2260 (cl:go pc-2260))
          (2261 (cl:go pc-2261))
          (2262 (cl:go pc-2262))
          (2263 (cl:go pc-2263))
          (2264 (cl:go pc-2264))
          (2265 (cl:go pc-2265))
          (2266 (cl:go pc-2266))
          (2267 (cl:go pc-2267))
          (2268 (cl:go pc-2268))
          (2269 (cl:go pc-2269))
          (2270 (cl:go pc-2270))
          (2271 (cl:go pc-2271))
          (2272 (cl:go pc-2272))
          (2273 (cl:go pc-2273))
          (2274 (cl:go pc-2274))
          (2275 (cl:go pc-2275))
          (2276 (cl:go pc-2276))
          (2277 (cl:go pc-2277))
          (2278 (cl:go pc-2278))
          (2279 (cl:go pc-2279))
          (2280 (cl:go pc-2280))
          (2281 (cl:go pc-2281))
          (2282 (cl:go pc-2282))
          (2283 (cl:go pc-2283))
          (2284 (cl:go pc-2284))
          (2285 (cl:go pc-2285))
          (2286 (cl:go pc-2286))
          (2287 (cl:go pc-2287))
          (2288 (cl:go pc-2288))
          (2289 (cl:go pc-2289))
          (2290 (cl:go pc-2290))
          (2291 (cl:go pc-2291))
          (2292 (cl:go pc-2292))
          (2293 (cl:go pc-2293))
          (2294 (cl:go pc-2294))
          (2295 (cl:go pc-2295))
          (2296 (cl:go pc-2296))
          (2297 (cl:go pc-2297))
          (2298 (cl:go pc-2298))
          (2299 (cl:go pc-2299))
          (2300 (cl:go pc-2300))
          (2301 (cl:go pc-2301))
          (2302 (cl:go pc-2302))
          (2303 (cl:go pc-2303))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 2560)
        (cl:case pc
          (2304 (cl:go pc-2304))
          (2305 (cl:go pc-2305))
          (2306 (cl:go pc-2306))
          (2307 (cl:go pc-2307))
          (2308 (cl:go pc-2308))
          (2309 (cl:go pc-2309))
          (2310 (cl:go pc-2310))
          (2311 (cl:go pc-2311))
          (2312 (cl:go pc-2312))
          (2313 (cl:go pc-2313))
          (2314 (cl:go pc-2314))
          (2315 (cl:go pc-2315))
          (2316 (cl:go pc-2316))
          (2317 (cl:go pc-2317))
          (2318 (cl:go pc-2318))
          (2319 (cl:go pc-2319))
          (2320 (cl:go pc-2320))
          (2321 (cl:go pc-2321))
          (2322 (cl:go pc-2322))
          (2323 (cl:go pc-2323))
          (2324 (cl:go pc-2324))
          (2325 (cl:go pc-2325))
          (2326 (cl:go pc-2326))
          (2327 (cl:go pc-2327))
          (2328 (cl:go pc-2328))
          (2329 (cl:go pc-2329))
          (2330 (cl:go pc-2330))
          (2331 (cl:go pc-2331))
          (2332 (cl:go pc-2332))
          (2333 (cl:go pc-2333))
          (2334 (cl:go pc-2334))
          (2335 (cl:go pc-2335))
          (2336 (cl:go pc-2336))
          (2337 (cl:go pc-2337))
          (2338 (cl:go pc-2338))
          (2339 (cl:go pc-2339))
          (2340 (cl:go pc-2340))
          (2341 (cl:go pc-2341))
          (2342 (cl:go pc-2342))
          (2343 (cl:go pc-2343))
          (2344 (cl:go pc-2344))
          (2345 (cl:go pc-2345))
          (2346 (cl:go pc-2346))
          (2347 (cl:go pc-2347))
          (2348 (cl:go pc-2348))
          (2349 (cl:go pc-2349))
          (2350 (cl:go pc-2350))
          (2351 (cl:go pc-2351))
          (2352 (cl:go pc-2352))
          (2353 (cl:go pc-2353))
          (2354 (cl:go pc-2354))
          (2355 (cl:go pc-2355))
          (2356 (cl:go pc-2356))
          (2357 (cl:go pc-2357))
          (2358 (cl:go pc-2358))
          (2359 (cl:go pc-2359))
          (2360 (cl:go pc-2360))
          (2361 (cl:go pc-2361))
          (2362 (cl:go pc-2362))
          (2363 (cl:go pc-2363))
          (2364 (cl:go pc-2364))
          (2365 (cl:go pc-2365))
          (2366 (cl:go pc-2366))
          (2367 (cl:go pc-2367))
          (2368 (cl:go pc-2368))
          (2369 (cl:go pc-2369))
          (2370 (cl:go pc-2370))
          (2371 (cl:go pc-2371))
          (2372 (cl:go pc-2372))
          (2373 (cl:go pc-2373))
          (2374 (cl:go pc-2374))
          (2375 (cl:go pc-2375))
          (2376 (cl:go pc-2376))
          (2377 (cl:go pc-2377))
          (2378 (cl:go pc-2378))
          (2379 (cl:go pc-2379))
          (2380 (cl:go pc-2380))
          (2381 (cl:go pc-2381))
          (2382 (cl:go pc-2382))
          (2383 (cl:go pc-2383))
          (2384 (cl:go pc-2384))
          (2385 (cl:go pc-2385))
          (2386 (cl:go pc-2386))
          (2387 (cl:go pc-2387))
          (2388 (cl:go pc-2388))
          (2389 (cl:go pc-2389))
          (2390 (cl:go pc-2390))
          (2391 (cl:go pc-2391))
          (2392 (cl:go pc-2392))
          (2393 (cl:go pc-2393))
          (2394 (cl:go pc-2394))
          (2395 (cl:go pc-2395))
          (2396 (cl:go pc-2396))
          (2397 (cl:go pc-2397))
          (2398 (cl:go pc-2398))
          (2399 (cl:go pc-2399))
          (2400 (cl:go pc-2400))
          (2401 (cl:go pc-2401))
          (2402 (cl:go pc-2402))
          (2403 (cl:go pc-2403))
          (2404 (cl:go pc-2404))
          (2405 (cl:go pc-2405))
          (2406 (cl:go pc-2406))
          (2407 (cl:go pc-2407))
          (2408 (cl:go pc-2408))
          (2409 (cl:go pc-2409))
          (2410 (cl:go pc-2410))
          (2411 (cl:go pc-2411))
          (2412 (cl:go pc-2412))
          (2413 (cl:go pc-2413))
          (2414 (cl:go pc-2414))
          (2415 (cl:go pc-2415))
          (2416 (cl:go pc-2416))
          (2417 (cl:go pc-2417))
          (2418 (cl:go pc-2418))
          (2419 (cl:go pc-2419))
          (2420 (cl:go pc-2420))
          (2421 (cl:go pc-2421))
          (2422 (cl:go pc-2422))
          (2423 (cl:go pc-2423))
          (2424 (cl:go pc-2424))
          (2425 (cl:go pc-2425))
          (2426 (cl:go pc-2426))
          (2427 (cl:go pc-2427))
          (2428 (cl:go pc-2428))
          (2429 (cl:go pc-2429))
          (2430 (cl:go pc-2430))
          (2431 (cl:go pc-2431))
          (2432 (cl:go pc-2432))
          (2433 (cl:go pc-2433))
          (2434 (cl:go pc-2434))
          (2435 (cl:go pc-2435))
          (2436 (cl:go pc-2436))
          (2437 (cl:go pc-2437))
          (2438 (cl:go pc-2438))
          (2439 (cl:go pc-2439))
          (2440 (cl:go pc-2440))
          (2441 (cl:go pc-2441))
          (2442 (cl:go pc-2442))
          (2443 (cl:go pc-2443))
          (2444 (cl:go pc-2444))
          (2445 (cl:go pc-2445))
          (2446 (cl:go pc-2446))
          (2447 (cl:go pc-2447))
          (2448 (cl:go pc-2448))
          (2449 (cl:go pc-2449))
          (2450 (cl:go pc-2450))
          (2451 (cl:go pc-2451))
          (2452 (cl:go pc-2452))
          (2453 (cl:go pc-2453))
          (2454 (cl:go pc-2454))
          (2455 (cl:go pc-2455))
          (2456 (cl:go pc-2456))
          (2457 (cl:go pc-2457))
          (2458 (cl:go pc-2458))
          (2459 (cl:go pc-2459))
          (2460 (cl:go pc-2460))
          (2461 (cl:go pc-2461))
          (2462 (cl:go pc-2462))
          (2463 (cl:go pc-2463))
          (2464 (cl:go pc-2464))
          (2465 (cl:go pc-2465))
          (2466 (cl:go pc-2466))
          (2467 (cl:go pc-2467))
          (2468 (cl:go pc-2468))
          (2469 (cl:go pc-2469))
          (2470 (cl:go pc-2470))
          (2471 (cl:go pc-2471))
          (2472 (cl:go pc-2472))
          (2473 (cl:go pc-2473))
          (2474 (cl:go pc-2474))
          (2475 (cl:go pc-2475))
          (2476 (cl:go pc-2476))
          (2477 (cl:go pc-2477))
          (2478 (cl:go pc-2478))
          (2479 (cl:go pc-2479))
          (2480 (cl:go pc-2480))
          (2481 (cl:go pc-2481))
          (2482 (cl:go pc-2482))
          (2483 (cl:go pc-2483))
          (2484 (cl:go pc-2484))
          (2485 (cl:go pc-2485))
          (2486 (cl:go pc-2486))
          (2487 (cl:go pc-2487))
          (2488 (cl:go pc-2488))
          (2489 (cl:go pc-2489))
          (2490 (cl:go pc-2490))
          (2491 (cl:go pc-2491))
          (2492 (cl:go pc-2492))
          (2493 (cl:go pc-2493))
          (2494 (cl:go pc-2494))
          (2495 (cl:go pc-2495))
          (2496 (cl:go pc-2496))
          (2497 (cl:go pc-2497))
          (2498 (cl:go pc-2498))
          (2499 (cl:go pc-2499))
          (2500 (cl:go pc-2500))
          (2501 (cl:go pc-2501))
          (2502 (cl:go pc-2502))
          (2503 (cl:go pc-2503))
          (2504 (cl:go pc-2504))
          (2505 (cl:go pc-2505))
          (2506 (cl:go pc-2506))
          (2507 (cl:go pc-2507))
          (2508 (cl:go pc-2508))
          (2509 (cl:go pc-2509))
          (2510 (cl:go pc-2510))
          (2511 (cl:go pc-2511))
          (2512 (cl:go pc-2512))
          (2513 (cl:go pc-2513))
          (2514 (cl:go pc-2514))
          (2515 (cl:go pc-2515))
          (2516 (cl:go pc-2516))
          (2517 (cl:go pc-2517))
          (2518 (cl:go pc-2518))
          (2519 (cl:go pc-2519))
          (2520 (cl:go pc-2520))
          (2521 (cl:go pc-2521))
          (2522 (cl:go pc-2522))
          (2523 (cl:go pc-2523))
          (2524 (cl:go pc-2524))
          (2525 (cl:go pc-2525))
          (2526 (cl:go pc-2526))
          (2527 (cl:go pc-2527))
          (2528 (cl:go pc-2528))
          (2529 (cl:go pc-2529))
          (2530 (cl:go pc-2530))
          (2531 (cl:go pc-2531))
          (2532 (cl:go pc-2532))
          (2533 (cl:go pc-2533))
          (2534 (cl:go pc-2534))
          (2535 (cl:go pc-2535))
          (2536 (cl:go pc-2536))
          (2537 (cl:go pc-2537))
          (2538 (cl:go pc-2538))
          (2539 (cl:go pc-2539))
          (2540 (cl:go pc-2540))
          (2541 (cl:go pc-2541))
          (2542 (cl:go pc-2542))
          (2543 (cl:go pc-2543))
          (2544 (cl:go pc-2544))
          (2545 (cl:go pc-2545))
          (2546 (cl:go pc-2546))
          (2547 (cl:go pc-2547))
          (2548 (cl:go pc-2548))
          (2549 (cl:go pc-2549))
          (2550 (cl:go pc-2550))
          (2551 (cl:go pc-2551))
          (2552 (cl:go pc-2552))
          (2553 (cl:go pc-2553))
          (2554 (cl:go pc-2554))
          (2555 (cl:go pc-2555))
          (2556 (cl:go pc-2556))
          (2557 (cl:go pc-2557))
          (2558 (cl:go pc-2558))
          (2559 (cl:go pc-2559))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 2816)
        (cl:case pc
          (2560 (cl:go pc-2560))
          (2561 (cl:go pc-2561))
          (2562 (cl:go pc-2562))
          (2563 (cl:go pc-2563))
          (2564 (cl:go pc-2564))
          (2565 (cl:go pc-2565))
          (2566 (cl:go pc-2566))
          (2567 (cl:go pc-2567))
          (2568 (cl:go pc-2568))
          (2569 (cl:go pc-2569))
          (2570 (cl:go pc-2570))
          (2571 (cl:go pc-2571))
          (2572 (cl:go pc-2572))
          (2573 (cl:go pc-2573))
          (2574 (cl:go pc-2574))
          (2575 (cl:go pc-2575))
          (2576 (cl:go pc-2576))
          (2577 (cl:go pc-2577))
          (2578 (cl:go pc-2578))
          (2579 (cl:go pc-2579))
          (2580 (cl:go pc-2580))
          (2581 (cl:go pc-2581))
          (2582 (cl:go pc-2582))
          (2583 (cl:go pc-2583))
          (2584 (cl:go pc-2584))
          (2585 (cl:go pc-2585))
          (2586 (cl:go pc-2586))
          (2587 (cl:go pc-2587))
          (2588 (cl:go pc-2588))
          (2589 (cl:go pc-2589))
          (2590 (cl:go pc-2590))
          (2591 (cl:go pc-2591))
          (2592 (cl:go pc-2592))
          (2593 (cl:go pc-2593))
          (2594 (cl:go pc-2594))
          (2595 (cl:go pc-2595))
          (2596 (cl:go pc-2596))
          (2597 (cl:go pc-2597))
          (2598 (cl:go pc-2598))
          (2599 (cl:go pc-2599))
          (2600 (cl:go pc-2600))
          (2601 (cl:go pc-2601))
          (2602 (cl:go pc-2602))
          (2603 (cl:go pc-2603))
          (2604 (cl:go pc-2604))
          (2605 (cl:go pc-2605))
          (2606 (cl:go pc-2606))
          (2607 (cl:go pc-2607))
          (2608 (cl:go pc-2608))
          (2609 (cl:go pc-2609))
          (2610 (cl:go pc-2610))
          (2611 (cl:go pc-2611))
          (2612 (cl:go pc-2612))
          (2613 (cl:go pc-2613))
          (2614 (cl:go pc-2614))
          (2615 (cl:go pc-2615))
          (2616 (cl:go pc-2616))
          (2617 (cl:go pc-2617))
          (2618 (cl:go pc-2618))
          (2619 (cl:go pc-2619))
          (2620 (cl:go pc-2620))
          (2621 (cl:go pc-2621))
          (2622 (cl:go pc-2622))
          (2623 (cl:go pc-2623))
          (2624 (cl:go pc-2624))
          (2625 (cl:go pc-2625))
          (2626 (cl:go pc-2626))
          (2627 (cl:go pc-2627))
          (2628 (cl:go pc-2628))
          (2629 (cl:go pc-2629))
          (2630 (cl:go pc-2630))
          (2631 (cl:go pc-2631))
          (2632 (cl:go pc-2632))
          (2633 (cl:go pc-2633))
          (2634 (cl:go pc-2634))
          (2635 (cl:go pc-2635))
          (2636 (cl:go pc-2636))
          (2637 (cl:go pc-2637))
          (2638 (cl:go pc-2638))
          (2639 (cl:go pc-2639))
          (2640 (cl:go pc-2640))
          (2641 (cl:go pc-2641))
          (2642 (cl:go pc-2642))
          (2643 (cl:go pc-2643))
          (2644 (cl:go pc-2644))
          (2645 (cl:go pc-2645))
          (2646 (cl:go pc-2646))
          (2647 (cl:go pc-2647))
          (2648 (cl:go pc-2648))
          (2649 (cl:go pc-2649))
          (2650 (cl:go pc-2650))
          (2651 (cl:go pc-2651))
          (2652 (cl:go pc-2652))
          (2653 (cl:go pc-2653))
          (2654 (cl:go pc-2654))
          (2655 (cl:go pc-2655))
          (2656 (cl:go pc-2656))
          (2657 (cl:go pc-2657))
          (2658 (cl:go pc-2658))
          (2659 (cl:go pc-2659))
          (2660 (cl:go pc-2660))
          (2661 (cl:go pc-2661))
          (2662 (cl:go pc-2662))
          (2663 (cl:go pc-2663))
          (2664 (cl:go pc-2664))
          (2665 (cl:go pc-2665))
          (2666 (cl:go pc-2666))
          (2667 (cl:go pc-2667))
          (2668 (cl:go pc-2668))
          (2669 (cl:go pc-2669))
          (2670 (cl:go pc-2670))
          (2671 (cl:go pc-2671))
          (2672 (cl:go pc-2672))
          (2673 (cl:go pc-2673))
          (2674 (cl:go pc-2674))
          (2675 (cl:go pc-2675))
          (2676 (cl:go pc-2676))
          (2677 (cl:go pc-2677))
          (2678 (cl:go pc-2678))
          (2679 (cl:go pc-2679))
          (2680 (cl:go pc-2680))
          (2681 (cl:go pc-2681))
          (2682 (cl:go pc-2682))
          (2683 (cl:go pc-2683))
          (2684 (cl:go pc-2684))
          (2685 (cl:go pc-2685))
          (2686 (cl:go pc-2686))
          (2687 (cl:go pc-2687))
          (2688 (cl:go pc-2688))
          (2689 (cl:go pc-2689))
          (2690 (cl:go pc-2690))
          (2691 (cl:go pc-2691))
          (2692 (cl:go pc-2692))
          (2693 (cl:go pc-2693))
          (2694 (cl:go pc-2694))
          (2695 (cl:go pc-2695))
          (2696 (cl:go pc-2696))
          (2697 (cl:go pc-2697))
          (2698 (cl:go pc-2698))
          (2699 (cl:go pc-2699))
          (2700 (cl:go pc-2700))
          (2701 (cl:go pc-2701))
          (2702 (cl:go pc-2702))
          (2703 (cl:go pc-2703))
          (2704 (cl:go pc-2704))
          (2705 (cl:go pc-2705))
          (2706 (cl:go pc-2706))
          (2707 (cl:go pc-2707))
          (2708 (cl:go pc-2708))
          (2709 (cl:go pc-2709))
          (2710 (cl:go pc-2710))
          (2711 (cl:go pc-2711))
          (2712 (cl:go pc-2712))
          (2713 (cl:go pc-2713))
          (2714 (cl:go pc-2714))
          (2715 (cl:go pc-2715))
          (2716 (cl:go pc-2716))
          (2717 (cl:go pc-2717))
          (2718 (cl:go pc-2718))
          (2719 (cl:go pc-2719))
          (2720 (cl:go pc-2720))
          (2721 (cl:go pc-2721))
          (2722 (cl:go pc-2722))
          (2723 (cl:go pc-2723))
          (2724 (cl:go pc-2724))
          (2725 (cl:go pc-2725))
          (2726 (cl:go pc-2726))
          (2727 (cl:go pc-2727))
          (2728 (cl:go pc-2728))
          (2729 (cl:go pc-2729))
          (2730 (cl:go pc-2730))
          (2731 (cl:go pc-2731))
          (2732 (cl:go pc-2732))
          (2733 (cl:go pc-2733))
          (2734 (cl:go pc-2734))
          (2735 (cl:go pc-2735))
          (2736 (cl:go pc-2736))
          (2737 (cl:go pc-2737))
          (2738 (cl:go pc-2738))
          (2739 (cl:go pc-2739))
          (2740 (cl:go pc-2740))
          (2741 (cl:go pc-2741))
          (2742 (cl:go pc-2742))
          (2743 (cl:go pc-2743))
          (2744 (cl:go pc-2744))
          (2745 (cl:go pc-2745))
          (2746 (cl:go pc-2746))
          (2747 (cl:go pc-2747))
          (2748 (cl:go pc-2748))
          (2749 (cl:go pc-2749))
          (2750 (cl:go pc-2750))
          (2751 (cl:go pc-2751))
          (2752 (cl:go pc-2752))
          (2753 (cl:go pc-2753))
          (2754 (cl:go pc-2754))
          (2755 (cl:go pc-2755))
          (2756 (cl:go pc-2756))
          (2757 (cl:go pc-2757))
          (2758 (cl:go pc-2758))
          (2759 (cl:go pc-2759))
          (2760 (cl:go pc-2760))
          (2761 (cl:go pc-2761))
          (2762 (cl:go pc-2762))
          (2763 (cl:go pc-2763))
          (2764 (cl:go pc-2764))
          (2765 (cl:go pc-2765))
          (2766 (cl:go pc-2766))
          (2767 (cl:go pc-2767))
          (2768 (cl:go pc-2768))
          (2769 (cl:go pc-2769))
          (2770 (cl:go pc-2770))
          (2771 (cl:go pc-2771))
          (2772 (cl:go pc-2772))
          (2773 (cl:go pc-2773))
          (2774 (cl:go pc-2774))
          (2775 (cl:go pc-2775))
          (2776 (cl:go pc-2776))
          (2777 (cl:go pc-2777))
          (2778 (cl:go pc-2778))
          (2779 (cl:go pc-2779))
          (2780 (cl:go pc-2780))
          (2781 (cl:go pc-2781))
          (2782 (cl:go pc-2782))
          (2783 (cl:go pc-2783))
          (2784 (cl:go pc-2784))
          (2785 (cl:go pc-2785))
          (2786 (cl:go pc-2786))
          (2787 (cl:go pc-2787))
          (2788 (cl:go pc-2788))
          (2789 (cl:go pc-2789))
          (2790 (cl:go pc-2790))
          (2791 (cl:go pc-2791))
          (2792 (cl:go pc-2792))
          (2793 (cl:go pc-2793))
          (2794 (cl:go pc-2794))
          (2795 (cl:go pc-2795))
          (2796 (cl:go pc-2796))
          (2797 (cl:go pc-2797))
          (2798 (cl:go pc-2798))
          (2799 (cl:go pc-2799))
          (2800 (cl:go pc-2800))
          (2801 (cl:go pc-2801))
          (2802 (cl:go pc-2802))
          (2803 (cl:go pc-2803))
          (2804 (cl:go pc-2804))
          (2805 (cl:go pc-2805))
          (2806 (cl:go pc-2806))
          (2807 (cl:go pc-2807))
          (2808 (cl:go pc-2808))
          (2809 (cl:go pc-2809))
          (2810 (cl:go pc-2810))
          (2811 (cl:go pc-2811))
          (2812 (cl:go pc-2812))
          (2813 (cl:go pc-2813))
          (2814 (cl:go pc-2814))
          (2815 (cl:go pc-2815))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 3072)
        (cl:case pc
          (2816 (cl:go pc-2816))
          (2817 (cl:go pc-2817))
          (2818 (cl:go pc-2818))
          (2819 (cl:go pc-2819))
          (2820 (cl:go pc-2820))
          (2821 (cl:go pc-2821))
          (2822 (cl:go pc-2822))
          (2823 (cl:go pc-2823))
          (2824 (cl:go pc-2824))
          (2825 (cl:go pc-2825))
          (2826 (cl:go pc-2826))
          (2827 (cl:go pc-2827))
          (2828 (cl:go pc-2828))
          (2829 (cl:go pc-2829))
          (2830 (cl:go pc-2830))
          (2831 (cl:go pc-2831))
          (2832 (cl:go pc-2832))
          (2833 (cl:go pc-2833))
          (2834 (cl:go pc-2834))
          (2835 (cl:go pc-2835))
          (2836 (cl:go pc-2836))
          (2837 (cl:go pc-2837))
          (2838 (cl:go pc-2838))
          (2839 (cl:go pc-2839))
          (2840 (cl:go pc-2840))
          (2841 (cl:go pc-2841))
          (2842 (cl:go pc-2842))
          (2843 (cl:go pc-2843))
          (2844 (cl:go pc-2844))
          (2845 (cl:go pc-2845))
          (2846 (cl:go pc-2846))
          (2847 (cl:go pc-2847))
          (2848 (cl:go pc-2848))
          (2849 (cl:go pc-2849))
          (2850 (cl:go pc-2850))
          (2851 (cl:go pc-2851))
          (2852 (cl:go pc-2852))
          (2853 (cl:go pc-2853))
          (2854 (cl:go pc-2854))
          (2855 (cl:go pc-2855))
          (2856 (cl:go pc-2856))
          (2857 (cl:go pc-2857))
          (2858 (cl:go pc-2858))
          (2859 (cl:go pc-2859))
          (2860 (cl:go pc-2860))
          (2861 (cl:go pc-2861))
          (2862 (cl:go pc-2862))
          (2863 (cl:go pc-2863))
          (2864 (cl:go pc-2864))
          (2865 (cl:go pc-2865))
          (2866 (cl:go pc-2866))
          (2867 (cl:go pc-2867))
          (2868 (cl:go pc-2868))
          (2869 (cl:go pc-2869))
          (2870 (cl:go pc-2870))
          (2871 (cl:go pc-2871))
          (2872 (cl:go pc-2872))
          (2873 (cl:go pc-2873))
          (2874 (cl:go pc-2874))
          (2875 (cl:go pc-2875))
          (2876 (cl:go pc-2876))
          (2877 (cl:go pc-2877))
          (2878 (cl:go pc-2878))
          (2879 (cl:go pc-2879))
          (2880 (cl:go pc-2880))
          (2881 (cl:go pc-2881))
          (2882 (cl:go pc-2882))
          (2883 (cl:go pc-2883))
          (2884 (cl:go pc-2884))
          (2885 (cl:go pc-2885))
          (2886 (cl:go pc-2886))
          (2887 (cl:go pc-2887))
          (2888 (cl:go pc-2888))
          (2889 (cl:go pc-2889))
          (2890 (cl:go pc-2890))
          (2891 (cl:go pc-2891))
          (2892 (cl:go pc-2892))
          (2893 (cl:go pc-2893))
          (2894 (cl:go pc-2894))
          (2895 (cl:go pc-2895))
          (2896 (cl:go pc-2896))
          (2897 (cl:go pc-2897))
          (2898 (cl:go pc-2898))
          (2899 (cl:go pc-2899))
          (2900 (cl:go pc-2900))
          (2901 (cl:go pc-2901))
          (2902 (cl:go pc-2902))
          (2903 (cl:go pc-2903))
          (2904 (cl:go pc-2904))
          (2905 (cl:go pc-2905))
          (2906 (cl:go pc-2906))
          (2907 (cl:go pc-2907))
          (2908 (cl:go pc-2908))
          (2909 (cl:go pc-2909))
          (2910 (cl:go pc-2910))
          (2911 (cl:go pc-2911))
          (2912 (cl:go pc-2912))
          (2913 (cl:go pc-2913))
          (2914 (cl:go pc-2914))
          (2915 (cl:go pc-2915))
          (2916 (cl:go pc-2916))
          (2917 (cl:go pc-2917))
          (2918 (cl:go pc-2918))
          (2919 (cl:go pc-2919))
          (2920 (cl:go pc-2920))
          (2921 (cl:go pc-2921))
          (2922 (cl:go pc-2922))
          (2923 (cl:go pc-2923))
          (2924 (cl:go pc-2924))
          (2925 (cl:go pc-2925))
          (2926 (cl:go pc-2926))
          (2927 (cl:go pc-2927))
          (2928 (cl:go pc-2928))
          (2929 (cl:go pc-2929))
          (2930 (cl:go pc-2930))
          (2931 (cl:go pc-2931))
          (2932 (cl:go pc-2932))
          (2933 (cl:go pc-2933))
          (2934 (cl:go pc-2934))
          (2935 (cl:go pc-2935))
          (2936 (cl:go pc-2936))
          (2937 (cl:go pc-2937))
          (2938 (cl:go pc-2938))
          (2939 (cl:go pc-2939))
          (2940 (cl:go pc-2940))
          (2941 (cl:go pc-2941))
          (2942 (cl:go pc-2942))
          (2943 (cl:go pc-2943))
          (2944 (cl:go pc-2944))
          (2945 (cl:go pc-2945))
          (2946 (cl:go pc-2946))
          (2947 (cl:go pc-2947))
          (2948 (cl:go pc-2948))
          (2949 (cl:go pc-2949))
          (2950 (cl:go pc-2950))
          (2951 (cl:go pc-2951))
          (2952 (cl:go pc-2952))
          (2953 (cl:go pc-2953))
          (2954 (cl:go pc-2954))
          (2955 (cl:go pc-2955))
          (2956 (cl:go pc-2956))
          (2957 (cl:go pc-2957))
          (2958 (cl:go pc-2958))
          (2959 (cl:go pc-2959))
          (2960 (cl:go pc-2960))
          (2961 (cl:go pc-2961))
          (2962 (cl:go pc-2962))
          (2963 (cl:go pc-2963))
          (2964 (cl:go pc-2964))
          (2965 (cl:go pc-2965))
          (2966 (cl:go pc-2966))
          (2967 (cl:go pc-2967))
          (2968 (cl:go pc-2968))
          (2969 (cl:go pc-2969))
          (2970 (cl:go pc-2970))
          (2971 (cl:go pc-2971))
          (2972 (cl:go pc-2972))
          (2973 (cl:go pc-2973))
          (2974 (cl:go pc-2974))
          (2975 (cl:go pc-2975))
          (2976 (cl:go pc-2976))
          (2977 (cl:go pc-2977))
          (2978 (cl:go pc-2978))
          (2979 (cl:go pc-2979))
          (2980 (cl:go pc-2980))
          (2981 (cl:go pc-2981))
          (2982 (cl:go pc-2982))
          (2983 (cl:go pc-2983))
          (2984 (cl:go pc-2984))
          (2985 (cl:go pc-2985))
          (2986 (cl:go pc-2986))
          (2987 (cl:go pc-2987))
          (2988 (cl:go pc-2988))
          (2989 (cl:go pc-2989))
          (2990 (cl:go pc-2990))
          (2991 (cl:go pc-2991))
          (2992 (cl:go pc-2992))
          (2993 (cl:go pc-2993))
          (2994 (cl:go pc-2994))
          (2995 (cl:go pc-2995))
          (2996 (cl:go pc-2996))
          (2997 (cl:go pc-2997))
          (2998 (cl:go pc-2998))
          (2999 (cl:go pc-2999))
          (3000 (cl:go pc-3000))
          (3001 (cl:go pc-3001))
          (3002 (cl:go pc-3002))
          (3003 (cl:go pc-3003))
          (3004 (cl:go pc-3004))
          (3005 (cl:go pc-3005))
          (3006 (cl:go pc-3006))
          (3007 (cl:go pc-3007))
          (3008 (cl:go pc-3008))
          (3009 (cl:go pc-3009))
          (3010 (cl:go pc-3010))
          (3011 (cl:go pc-3011))
          (3012 (cl:go pc-3012))
          (3013 (cl:go pc-3013))
          (3014 (cl:go pc-3014))
          (3015 (cl:go pc-3015))
          (3016 (cl:go pc-3016))
          (3017 (cl:go pc-3017))
          (3018 (cl:go pc-3018))
          (3019 (cl:go pc-3019))
          (3020 (cl:go pc-3020))
          (3021 (cl:go pc-3021))
          (3022 (cl:go pc-3022))
          (3023 (cl:go pc-3023))
          (3024 (cl:go pc-3024))
          (3025 (cl:go pc-3025))
          (3026 (cl:go pc-3026))
          (3027 (cl:go pc-3027))
          (3028 (cl:go pc-3028))
          (3029 (cl:go pc-3029))
          (3030 (cl:go pc-3030))
          (3031 (cl:go pc-3031))
          (3032 (cl:go pc-3032))
          (3033 (cl:go pc-3033))
          (3034 (cl:go pc-3034))
          (3035 (cl:go pc-3035))
          (3036 (cl:go pc-3036))
          (3037 (cl:go pc-3037))
          (3038 (cl:go pc-3038))
          (3039 (cl:go pc-3039))
          (3040 (cl:go pc-3040))
          (3041 (cl:go pc-3041))
          (3042 (cl:go pc-3042))
          (3043 (cl:go pc-3043))
          (3044 (cl:go pc-3044))
          (3045 (cl:go pc-3045))
          (3046 (cl:go pc-3046))
          (3047 (cl:go pc-3047))
          (3048 (cl:go pc-3048))
          (3049 (cl:go pc-3049))
          (3050 (cl:go pc-3050))
          (3051 (cl:go pc-3051))
          (3052 (cl:go pc-3052))
          (3053 (cl:go pc-3053))
          (3054 (cl:go pc-3054))
          (3055 (cl:go pc-3055))
          (3056 (cl:go pc-3056))
          (3057 (cl:go pc-3057))
          (3058 (cl:go pc-3058))
          (3059 (cl:go pc-3059))
          (3060 (cl:go pc-3060))
          (3061 (cl:go pc-3061))
          (3062 (cl:go pc-3062))
          (3063 (cl:go pc-3063))
          (3064 (cl:go pc-3064))
          (3065 (cl:go pc-3065))
          (3066 (cl:go pc-3066))
          (3067 (cl:go pc-3067))
          (3068 (cl:go pc-3068))
          (3069 (cl:go pc-3069))
          (3070 (cl:go pc-3070))
          (3071 (cl:go pc-3071))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 3328)
        (cl:case pc
          (3072 (cl:go pc-3072))
          (3073 (cl:go pc-3073))
          (3074 (cl:go pc-3074))
          (3075 (cl:go pc-3075))
          (3076 (cl:go pc-3076))
          (3077 (cl:go pc-3077))
          (3078 (cl:go pc-3078))
          (3079 (cl:go pc-3079))
          (3080 (cl:go pc-3080))
          (3081 (cl:go pc-3081))
          (3082 (cl:go pc-3082))
          (3083 (cl:go pc-3083))
          (3084 (cl:go pc-3084))
          (3085 (cl:go pc-3085))
          (3086 (cl:go pc-3086))
          (3087 (cl:go pc-3087))
          (3088 (cl:go pc-3088))
          (3089 (cl:go pc-3089))
          (3090 (cl:go pc-3090))
          (3091 (cl:go pc-3091))
          (3092 (cl:go pc-3092))
          (3093 (cl:go pc-3093))
          (3094 (cl:go pc-3094))
          (3095 (cl:go pc-3095))
          (3096 (cl:go pc-3096))
          (3097 (cl:go pc-3097))
          (3098 (cl:go pc-3098))
          (3099 (cl:go pc-3099))
          (3100 (cl:go pc-3100))
          (3101 (cl:go pc-3101))
          (3102 (cl:go pc-3102))
          (3103 (cl:go pc-3103))
          (3104 (cl:go pc-3104))
          (3105 (cl:go pc-3105))
          (3106 (cl:go pc-3106))
          (3107 (cl:go pc-3107))
          (3108 (cl:go pc-3108))
          (3109 (cl:go pc-3109))
          (3110 (cl:go pc-3110))
          (3111 (cl:go pc-3111))
          (3112 (cl:go pc-3112))
          (3113 (cl:go pc-3113))
          (3114 (cl:go pc-3114))
          (3115 (cl:go pc-3115))
          (3116 (cl:go pc-3116))
          (3117 (cl:go pc-3117))
          (3118 (cl:go pc-3118))
          (3119 (cl:go pc-3119))
          (3120 (cl:go pc-3120))
          (3121 (cl:go pc-3121))
          (3122 (cl:go pc-3122))
          (3123 (cl:go pc-3123))
          (3124 (cl:go pc-3124))
          (3125 (cl:go pc-3125))
          (3126 (cl:go pc-3126))
          (3127 (cl:go pc-3127))
          (3128 (cl:go pc-3128))
          (3129 (cl:go pc-3129))
          (3130 (cl:go pc-3130))
          (3131 (cl:go pc-3131))
          (3132 (cl:go pc-3132))
          (3133 (cl:go pc-3133))
          (3134 (cl:go pc-3134))
          (3135 (cl:go pc-3135))
          (3136 (cl:go pc-3136))
          (3137 (cl:go pc-3137))
          (3138 (cl:go pc-3138))
          (3139 (cl:go pc-3139))
          (3140 (cl:go pc-3140))
          (3141 (cl:go pc-3141))
          (3142 (cl:go pc-3142))
          (3143 (cl:go pc-3143))
          (3144 (cl:go pc-3144))
          (3145 (cl:go pc-3145))
          (3146 (cl:go pc-3146))
          (3147 (cl:go pc-3147))
          (3148 (cl:go pc-3148))
          (3149 (cl:go pc-3149))
          (3150 (cl:go pc-3150))
          (3151 (cl:go pc-3151))
          (3152 (cl:go pc-3152))
          (3153 (cl:go pc-3153))
          (3154 (cl:go pc-3154))
          (3155 (cl:go pc-3155))
          (3156 (cl:go pc-3156))
          (3157 (cl:go pc-3157))
          (3158 (cl:go pc-3158))
          (3159 (cl:go pc-3159))
          (3160 (cl:go pc-3160))
          (3161 (cl:go pc-3161))
          (3162 (cl:go pc-3162))
          (3163 (cl:go pc-3163))
          (3164 (cl:go pc-3164))
          (3165 (cl:go pc-3165))
          (3166 (cl:go pc-3166))
          (3167 (cl:go pc-3167))
          (3168 (cl:go pc-3168))
          (3169 (cl:go pc-3169))
          (3170 (cl:go pc-3170))
          (3171 (cl:go pc-3171))
          (3172 (cl:go pc-3172))
          (3173 (cl:go pc-3173))
          (3174 (cl:go pc-3174))
          (3175 (cl:go pc-3175))
          (3176 (cl:go pc-3176))
          (3177 (cl:go pc-3177))
          (3178 (cl:go pc-3178))
          (3179 (cl:go pc-3179))
          (3180 (cl:go pc-3180))
          (3181 (cl:go pc-3181))
          (3182 (cl:go pc-3182))
          (3183 (cl:go pc-3183))
          (3184 (cl:go pc-3184))
          (3185 (cl:go pc-3185))
          (3186 (cl:go pc-3186))
          (3187 (cl:go pc-3187))
          (3188 (cl:go pc-3188))
          (3189 (cl:go pc-3189))
          (3190 (cl:go pc-3190))
          (3191 (cl:go pc-3191))
          (3192 (cl:go pc-3192))
          (3193 (cl:go pc-3193))
          (3194 (cl:go pc-3194))
          (3195 (cl:go pc-3195))
          (3196 (cl:go pc-3196))
          (3197 (cl:go pc-3197))
          (3198 (cl:go pc-3198))
          (3199 (cl:go pc-3199))
          (3200 (cl:go pc-3200))
          (3201 (cl:go pc-3201))
          (3202 (cl:go pc-3202))
          (3203 (cl:go pc-3203))
          (3204 (cl:go pc-3204))
          (3205 (cl:go pc-3205))
          (3206 (cl:go pc-3206))
          (3207 (cl:go pc-3207))
          (3208 (cl:go pc-3208))
          (3209 (cl:go pc-3209))
          (3210 (cl:go pc-3210))
          (3211 (cl:go pc-3211))
          (3212 (cl:go pc-3212))
          (3213 (cl:go pc-3213))
          (3214 (cl:go pc-3214))
          (3215 (cl:go pc-3215))
          (3216 (cl:go pc-3216))
          (3217 (cl:go pc-3217))
          (3218 (cl:go pc-3218))
          (3219 (cl:go pc-3219))
          (3220 (cl:go pc-3220))
          (3221 (cl:go pc-3221))
          (3222 (cl:go pc-3222))
          (3223 (cl:go pc-3223))
          (3224 (cl:go pc-3224))
          (3225 (cl:go pc-3225))
          (3226 (cl:go pc-3226))
          (3227 (cl:go pc-3227))
          (3228 (cl:go pc-3228))
          (3229 (cl:go pc-3229))
          (3230 (cl:go pc-3230))
          (3231 (cl:go pc-3231))
          (3232 (cl:go pc-3232))
          (3233 (cl:go pc-3233))
          (3234 (cl:go pc-3234))
          (3235 (cl:go pc-3235))
          (3236 (cl:go pc-3236))
          (3237 (cl:go pc-3237))
          (3238 (cl:go pc-3238))
          (3239 (cl:go pc-3239))
          (3240 (cl:go pc-3240))
          (3241 (cl:go pc-3241))
          (3242 (cl:go pc-3242))
          (3243 (cl:go pc-3243))
          (3244 (cl:go pc-3244))
          (3245 (cl:go pc-3245))
          (3246 (cl:go pc-3246))
          (3247 (cl:go pc-3247))
          (3248 (cl:go pc-3248))
          (3249 (cl:go pc-3249))
          (3250 (cl:go pc-3250))
          (3251 (cl:go pc-3251))
          (3252 (cl:go pc-3252))
          (3253 (cl:go pc-3253))
          (3254 (cl:go pc-3254))
          (3255 (cl:go pc-3255))
          (3256 (cl:go pc-3256))
          (3257 (cl:go pc-3257))
          (3258 (cl:go pc-3258))
          (3259 (cl:go pc-3259))
          (3260 (cl:go pc-3260))
          (3261 (cl:go pc-3261))
          (3262 (cl:go pc-3262))
          (3263 (cl:go pc-3263))
          (3264 (cl:go pc-3264))
          (3265 (cl:go pc-3265))
          (3266 (cl:go pc-3266))
          (3267 (cl:go pc-3267))
          (3268 (cl:go pc-3268))
          (3269 (cl:go pc-3269))
          (3270 (cl:go pc-3270))
          (3271 (cl:go pc-3271))
          (3272 (cl:go pc-3272))
          (3273 (cl:go pc-3273))
          (3274 (cl:go pc-3274))
          (3275 (cl:go pc-3275))
          (3276 (cl:go pc-3276))
          (3277 (cl:go pc-3277))
          (3278 (cl:go pc-3278))
          (3279 (cl:go pc-3279))
          (3280 (cl:go pc-3280))
          (3281 (cl:go pc-3281))
          (3282 (cl:go pc-3282))
          (3283 (cl:go pc-3283))
          (3284 (cl:go pc-3284))
          (3285 (cl:go pc-3285))
          (3286 (cl:go pc-3286))
          (3287 (cl:go pc-3287))
          (3288 (cl:go pc-3288))
          (3289 (cl:go pc-3289))
          (3290 (cl:go pc-3290))
          (3291 (cl:go pc-3291))
          (3292 (cl:go pc-3292))
          (3293 (cl:go pc-3293))
          (3294 (cl:go pc-3294))
          (3295 (cl:go pc-3295))
          (3296 (cl:go pc-3296))
          (3297 (cl:go pc-3297))
          (3298 (cl:go pc-3298))
          (3299 (cl:go pc-3299))
          (3300 (cl:go pc-3300))
          (3301 (cl:go pc-3301))
          (3302 (cl:go pc-3302))
          (3303 (cl:go pc-3303))
          (3304 (cl:go pc-3304))
          (3305 (cl:go pc-3305))
          (3306 (cl:go pc-3306))
          (3307 (cl:go pc-3307))
          (3308 (cl:go pc-3308))
          (3309 (cl:go pc-3309))
          (3310 (cl:go pc-3310))
          (3311 (cl:go pc-3311))
          (3312 (cl:go pc-3312))
          (3313 (cl:go pc-3313))
          (3314 (cl:go pc-3314))
          (3315 (cl:go pc-3315))
          (3316 (cl:go pc-3316))
          (3317 (cl:go pc-3317))
          (3318 (cl:go pc-3318))
          (3319 (cl:go pc-3319))
          (3320 (cl:go pc-3320))
          (3321 (cl:go pc-3321))
          (3322 (cl:go pc-3322))
          (3323 (cl:go pc-3323))
          (3324 (cl:go pc-3324))
          (3325 (cl:go pc-3325))
          (3326 (cl:go pc-3326))
          (3327 (cl:go pc-3327))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 3584)
        (cl:case pc
          (3328 (cl:go pc-3328))
          (3329 (cl:go pc-3329))
          (3330 (cl:go pc-3330))
          (3331 (cl:go pc-3331))
          (3332 (cl:go pc-3332))
          (3333 (cl:go pc-3333))
          (3334 (cl:go pc-3334))
          (3335 (cl:go pc-3335))
          (3336 (cl:go pc-3336))
          (3337 (cl:go pc-3337))
          (3338 (cl:go pc-3338))
          (3339 (cl:go pc-3339))
          (3340 (cl:go pc-3340))
          (3341 (cl:go pc-3341))
          (3342 (cl:go pc-3342))
          (3343 (cl:go pc-3343))
          (3344 (cl:go pc-3344))
          (3345 (cl:go pc-3345))
          (3346 (cl:go pc-3346))
          (3347 (cl:go pc-3347))
          (3348 (cl:go pc-3348))
          (3349 (cl:go pc-3349))
          (3350 (cl:go pc-3350))
          (3351 (cl:go pc-3351))
          (3352 (cl:go pc-3352))
          (3353 (cl:go pc-3353))
          (3354 (cl:go pc-3354))
          (3355 (cl:go pc-3355))
          (3356 (cl:go pc-3356))
          (3357 (cl:go pc-3357))
          (3358 (cl:go pc-3358))
          (3359 (cl:go pc-3359))
          (3360 (cl:go pc-3360))
          (3361 (cl:go pc-3361))
          (3362 (cl:go pc-3362))
          (3363 (cl:go pc-3363))
          (3364 (cl:go pc-3364))
          (3365 (cl:go pc-3365))
          (3366 (cl:go pc-3366))
          (3367 (cl:go pc-3367))
          (3368 (cl:go pc-3368))
          (3369 (cl:go pc-3369))
          (3370 (cl:go pc-3370))
          (3371 (cl:go pc-3371))
          (3372 (cl:go pc-3372))
          (3373 (cl:go pc-3373))
          (3374 (cl:go pc-3374))
          (3375 (cl:go pc-3375))
          (3376 (cl:go pc-3376))
          (3377 (cl:go pc-3377))
          (3378 (cl:go pc-3378))
          (3379 (cl:go pc-3379))
          (3380 (cl:go pc-3380))
          (3381 (cl:go pc-3381))
          (3382 (cl:go pc-3382))
          (3383 (cl:go pc-3383))
          (3384 (cl:go pc-3384))
          (3385 (cl:go pc-3385))
          (3386 (cl:go pc-3386))
          (3387 (cl:go pc-3387))
          (3388 (cl:go pc-3388))
          (3389 (cl:go pc-3389))
          (3390 (cl:go pc-3390))
          (3391 (cl:go pc-3391))
          (3392 (cl:go pc-3392))
          (3393 (cl:go pc-3393))
          (3394 (cl:go pc-3394))
          (3395 (cl:go pc-3395))
          (3396 (cl:go pc-3396))
          (3397 (cl:go pc-3397))
          (3398 (cl:go pc-3398))
          (3399 (cl:go pc-3399))
          (3400 (cl:go pc-3400))
          (3401 (cl:go pc-3401))
          (3402 (cl:go pc-3402))
          (3403 (cl:go pc-3403))
          (3404 (cl:go pc-3404))
          (3405 (cl:go pc-3405))
          (3406 (cl:go pc-3406))
          (3407 (cl:go pc-3407))
          (3408 (cl:go pc-3408))
          (3409 (cl:go pc-3409))
          (3410 (cl:go pc-3410))
          (3411 (cl:go pc-3411))
          (3412 (cl:go pc-3412))
          (3413 (cl:go pc-3413))
          (3414 (cl:go pc-3414))
          (3415 (cl:go pc-3415))
          (3416 (cl:go pc-3416))
          (3417 (cl:go pc-3417))
          (3418 (cl:go pc-3418))
          (3419 (cl:go pc-3419))
          (3420 (cl:go pc-3420))
          (3421 (cl:go pc-3421))
          (3422 (cl:go pc-3422))
          (3423 (cl:go pc-3423))
          (3424 (cl:go pc-3424))
          (3425 (cl:go pc-3425))
          (3426 (cl:go pc-3426))
          (3427 (cl:go pc-3427))
          (3428 (cl:go pc-3428))
          (3429 (cl:go pc-3429))
          (3430 (cl:go pc-3430))
          (3431 (cl:go pc-3431))
          (3432 (cl:go pc-3432))
          (3433 (cl:go pc-3433))
          (3434 (cl:go pc-3434))
          (3435 (cl:go pc-3435))
          (3436 (cl:go pc-3436))
          (3437 (cl:go pc-3437))
          (3438 (cl:go pc-3438))
          (3439 (cl:go pc-3439))
          (3440 (cl:go pc-3440))
          (3441 (cl:go pc-3441))
          (3442 (cl:go pc-3442))
          (3443 (cl:go pc-3443))
          (3444 (cl:go pc-3444))
          (3445 (cl:go pc-3445))
          (3446 (cl:go pc-3446))
          (3447 (cl:go pc-3447))
          (3448 (cl:go pc-3448))
          (3449 (cl:go pc-3449))
          (3450 (cl:go pc-3450))
          (3451 (cl:go pc-3451))
          (3452 (cl:go pc-3452))
          (3453 (cl:go pc-3453))
          (3454 (cl:go pc-3454))
          (3455 (cl:go pc-3455))
          (3456 (cl:go pc-3456))
          (3457 (cl:go pc-3457))
          (3458 (cl:go pc-3458))
          (3459 (cl:go pc-3459))
          (3460 (cl:go pc-3460))
          (3461 (cl:go pc-3461))
          (3462 (cl:go pc-3462))
          (3463 (cl:go pc-3463))
          (3464 (cl:go pc-3464))
          (3465 (cl:go pc-3465))
          (3466 (cl:go pc-3466))
          (3467 (cl:go pc-3467))
          (3468 (cl:go pc-3468))
          (3469 (cl:go pc-3469))
          (3470 (cl:go pc-3470))
          (3471 (cl:go pc-3471))
          (3472 (cl:go pc-3472))
          (3473 (cl:go pc-3473))
          (3474 (cl:go pc-3474))
          (3475 (cl:go pc-3475))
          (3476 (cl:go pc-3476))
          (3477 (cl:go pc-3477))
          (3478 (cl:go pc-3478))
          (3479 (cl:go pc-3479))
          (3480 (cl:go pc-3480))
          (3481 (cl:go pc-3481))
          (3482 (cl:go pc-3482))
          (3483 (cl:go pc-3483))
          (3484 (cl:go pc-3484))
          (3485 (cl:go pc-3485))
          (3486 (cl:go pc-3486))
          (3487 (cl:go pc-3487))
          (3488 (cl:go pc-3488))
          (3489 (cl:go pc-3489))
          (3490 (cl:go pc-3490))
          (3491 (cl:go pc-3491))
          (3492 (cl:go pc-3492))
          (3493 (cl:go pc-3493))
          (3494 (cl:go pc-3494))
          (3495 (cl:go pc-3495))
          (3496 (cl:go pc-3496))
          (3497 (cl:go pc-3497))
          (3498 (cl:go pc-3498))
          (3499 (cl:go pc-3499))
          (3500 (cl:go pc-3500))
          (3501 (cl:go pc-3501))
          (3502 (cl:go pc-3502))
          (3503 (cl:go pc-3503))
          (3504 (cl:go pc-3504))
          (3505 (cl:go pc-3505))
          (3506 (cl:go pc-3506))
          (3507 (cl:go pc-3507))
          (3508 (cl:go pc-3508))
          (3509 (cl:go pc-3509))
          (3510 (cl:go pc-3510))
          (3511 (cl:go pc-3511))
          (3512 (cl:go pc-3512))
          (3513 (cl:go pc-3513))
          (3514 (cl:go pc-3514))
          (3515 (cl:go pc-3515))
          (3516 (cl:go pc-3516))
          (3517 (cl:go pc-3517))
          (3518 (cl:go pc-3518))
          (3519 (cl:go pc-3519))
          (3520 (cl:go pc-3520))
          (3521 (cl:go pc-3521))
          (3522 (cl:go pc-3522))
          (3523 (cl:go pc-3523))
          (3524 (cl:go pc-3524))
          (3525 (cl:go pc-3525))
          (3526 (cl:go pc-3526))
          (3527 (cl:go pc-3527))
          (3528 (cl:go pc-3528))
          (3529 (cl:go pc-3529))
          (3530 (cl:go pc-3530))
          (3531 (cl:go pc-3531))
          (3532 (cl:go pc-3532))
          (3533 (cl:go pc-3533))
          (3534 (cl:go pc-3534))
          (3535 (cl:go pc-3535))
          (3536 (cl:go pc-3536))
          (3537 (cl:go pc-3537))
          (3538 (cl:go pc-3538))
          (3539 (cl:go pc-3539))
          (3540 (cl:go pc-3540))
          (3541 (cl:go pc-3541))
          (3542 (cl:go pc-3542))
          (3543 (cl:go pc-3543))
          (3544 (cl:go pc-3544))
          (3545 (cl:go pc-3545))
          (3546 (cl:go pc-3546))
          (3547 (cl:go pc-3547))
          (3548 (cl:go pc-3548))
          (3549 (cl:go pc-3549))
          (3550 (cl:go pc-3550))
          (3551 (cl:go pc-3551))
          (3552 (cl:go pc-3552))
          (3553 (cl:go pc-3553))
          (3554 (cl:go pc-3554))
          (3555 (cl:go pc-3555))
          (3556 (cl:go pc-3556))
          (3557 (cl:go pc-3557))
          (3558 (cl:go pc-3558))
          (3559 (cl:go pc-3559))
          (3560 (cl:go pc-3560))
          (3561 (cl:go pc-3561))
          (3562 (cl:go pc-3562))
          (3563 (cl:go pc-3563))
          (3564 (cl:go pc-3564))
          (3565 (cl:go pc-3565))
          (3566 (cl:go pc-3566))
          (3567 (cl:go pc-3567))
          (3568 (cl:go pc-3568))
          (3569 (cl:go pc-3569))
          (3570 (cl:go pc-3570))
          (3571 (cl:go pc-3571))
          (3572 (cl:go pc-3572))
          (3573 (cl:go pc-3573))
          (3574 (cl:go pc-3574))
          (3575 (cl:go pc-3575))
          (3576 (cl:go pc-3576))
          (3577 (cl:go pc-3577))
          (3578 (cl:go pc-3578))
          (3579 (cl:go pc-3579))
          (3580 (cl:go pc-3580))
          (3581 (cl:go pc-3581))
          (3582 (cl:go pc-3582))
          (3583 (cl:go pc-3583))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 3840)
        (cl:case pc
          (3584 (cl:go pc-3584))
          (3585 (cl:go pc-3585))
          (3586 (cl:go pc-3586))
          (3587 (cl:go pc-3587))
          (3588 (cl:go pc-3588))
          (3589 (cl:go pc-3589))
          (3590 (cl:go pc-3590))
          (3591 (cl:go pc-3591))
          (3592 (cl:go pc-3592))
          (3593 (cl:go pc-3593))
          (3594 (cl:go pc-3594))
          (3595 (cl:go pc-3595))
          (3596 (cl:go pc-3596))
          (3597 (cl:go pc-3597))
          (3598 (cl:go pc-3598))
          (3599 (cl:go pc-3599))
          (3600 (cl:go pc-3600))
          (3601 (cl:go pc-3601))
          (3602 (cl:go pc-3602))
          (3603 (cl:go pc-3603))
          (3604 (cl:go pc-3604))
          (3605 (cl:go pc-3605))
          (3606 (cl:go pc-3606))
          (3607 (cl:go pc-3607))
          (3608 (cl:go pc-3608))
          (3609 (cl:go pc-3609))
          (3610 (cl:go pc-3610))
          (3611 (cl:go pc-3611))
          (3612 (cl:go pc-3612))
          (3613 (cl:go pc-3613))
          (3614 (cl:go pc-3614))
          (3615 (cl:go pc-3615))
          (3616 (cl:go pc-3616))
          (3617 (cl:go pc-3617))
          (3618 (cl:go pc-3618))
          (3619 (cl:go pc-3619))
          (3620 (cl:go pc-3620))
          (3621 (cl:go pc-3621))
          (3622 (cl:go pc-3622))
          (3623 (cl:go pc-3623))
          (3624 (cl:go pc-3624))
          (3625 (cl:go pc-3625))
          (3626 (cl:go pc-3626))
          (3627 (cl:go pc-3627))
          (3628 (cl:go pc-3628))
          (3629 (cl:go pc-3629))
          (3630 (cl:go pc-3630))
          (3631 (cl:go pc-3631))
          (3632 (cl:go pc-3632))
          (3633 (cl:go pc-3633))
          (3634 (cl:go pc-3634))
          (3635 (cl:go pc-3635))
          (3636 (cl:go pc-3636))
          (3637 (cl:go pc-3637))
          (3638 (cl:go pc-3638))
          (3639 (cl:go pc-3639))
          (3640 (cl:go pc-3640))
          (3641 (cl:go pc-3641))
          (3642 (cl:go pc-3642))
          (3643 (cl:go pc-3643))
          (3644 (cl:go pc-3644))
          (3645 (cl:go pc-3645))
          (3646 (cl:go pc-3646))
          (3647 (cl:go pc-3647))
          (3648 (cl:go pc-3648))
          (3649 (cl:go pc-3649))
          (3650 (cl:go pc-3650))
          (3651 (cl:go pc-3651))
          (3652 (cl:go pc-3652))
          (3653 (cl:go pc-3653))
          (3654 (cl:go pc-3654))
          (3655 (cl:go pc-3655))
          (3656 (cl:go pc-3656))
          (3657 (cl:go pc-3657))
          (3658 (cl:go pc-3658))
          (3659 (cl:go pc-3659))
          (3660 (cl:go pc-3660))
          (3661 (cl:go pc-3661))
          (3662 (cl:go pc-3662))
          (3663 (cl:go pc-3663))
          (3664 (cl:go pc-3664))
          (3665 (cl:go pc-3665))
          (3666 (cl:go pc-3666))
          (3667 (cl:go pc-3667))
          (3668 (cl:go pc-3668))
          (3669 (cl:go pc-3669))
          (3670 (cl:go pc-3670))
          (3671 (cl:go pc-3671))
          (3672 (cl:go pc-3672))
          (3673 (cl:go pc-3673))
          (3674 (cl:go pc-3674))
          (3675 (cl:go pc-3675))
          (3676 (cl:go pc-3676))
          (3677 (cl:go pc-3677))
          (3678 (cl:go pc-3678))
          (3679 (cl:go pc-3679))
          (3680 (cl:go pc-3680))
          (3681 (cl:go pc-3681))
          (3682 (cl:go pc-3682))
          (3683 (cl:go pc-3683))
          (3684 (cl:go pc-3684))
          (3685 (cl:go pc-3685))
          (3686 (cl:go pc-3686))
          (3687 (cl:go pc-3687))
          (3688 (cl:go pc-3688))
          (3689 (cl:go pc-3689))
          (3690 (cl:go pc-3690))
          (3691 (cl:go pc-3691))
          (3692 (cl:go pc-3692))
          (3693 (cl:go pc-3693))
          (3694 (cl:go pc-3694))
          (3695 (cl:go pc-3695))
          (3696 (cl:go pc-3696))
          (3697 (cl:go pc-3697))
          (3698 (cl:go pc-3698))
          (3699 (cl:go pc-3699))
          (3700 (cl:go pc-3700))
          (3701 (cl:go pc-3701))
          (3702 (cl:go pc-3702))
          (3703 (cl:go pc-3703))
          (3704 (cl:go pc-3704))
          (3705 (cl:go pc-3705))
          (3706 (cl:go pc-3706))
          (3707 (cl:go pc-3707))
          (3708 (cl:go pc-3708))
          (3709 (cl:go pc-3709))
          (3710 (cl:go pc-3710))
          (3711 (cl:go pc-3711))
          (3712 (cl:go pc-3712))
          (3713 (cl:go pc-3713))
          (3714 (cl:go pc-3714))
          (3715 (cl:go pc-3715))
          (3716 (cl:go pc-3716))
          (3717 (cl:go pc-3717))
          (3718 (cl:go pc-3718))
          (3719 (cl:go pc-3719))
          (3720 (cl:go pc-3720))
          (3721 (cl:go pc-3721))
          (3722 (cl:go pc-3722))
          (3723 (cl:go pc-3723))
          (3724 (cl:go pc-3724))
          (3725 (cl:go pc-3725))
          (3726 (cl:go pc-3726))
          (3727 (cl:go pc-3727))
          (3728 (cl:go pc-3728))
          (3729 (cl:go pc-3729))
          (3730 (cl:go pc-3730))
          (3731 (cl:go pc-3731))
          (3732 (cl:go pc-3732))
          (3733 (cl:go pc-3733))
          (3734 (cl:go pc-3734))
          (3735 (cl:go pc-3735))
          (3736 (cl:go pc-3736))
          (3737 (cl:go pc-3737))
          (3738 (cl:go pc-3738))
          (3739 (cl:go pc-3739))
          (3740 (cl:go pc-3740))
          (3741 (cl:go pc-3741))
          (3742 (cl:go pc-3742))
          (3743 (cl:go pc-3743))
          (3744 (cl:go pc-3744))
          (3745 (cl:go pc-3745))
          (3746 (cl:go pc-3746))
          (3747 (cl:go pc-3747))
          (3748 (cl:go pc-3748))
          (3749 (cl:go pc-3749))
          (3750 (cl:go pc-3750))
          (3751 (cl:go pc-3751))
          (3752 (cl:go pc-3752))
          (3753 (cl:go pc-3753))
          (3754 (cl:go pc-3754))
          (3755 (cl:go pc-3755))
          (3756 (cl:go pc-3756))
          (3757 (cl:go pc-3757))
          (3758 (cl:go pc-3758))
          (3759 (cl:go pc-3759))
          (3760 (cl:go pc-3760))
          (3761 (cl:go pc-3761))
          (3762 (cl:go pc-3762))
          (3763 (cl:go pc-3763))
          (3764 (cl:go pc-3764))
          (3765 (cl:go pc-3765))
          (3766 (cl:go pc-3766))
          (3767 (cl:go pc-3767))
          (3768 (cl:go pc-3768))
          (3769 (cl:go pc-3769))
          (3770 (cl:go pc-3770))
          (3771 (cl:go pc-3771))
          (3772 (cl:go pc-3772))
          (3773 (cl:go pc-3773))
          (3774 (cl:go pc-3774))
          (3775 (cl:go pc-3775))
          (3776 (cl:go pc-3776))
          (3777 (cl:go pc-3777))
          (3778 (cl:go pc-3778))
          (3779 (cl:go pc-3779))
          (3780 (cl:go pc-3780))
          (3781 (cl:go pc-3781))
          (3782 (cl:go pc-3782))
          (3783 (cl:go pc-3783))
          (3784 (cl:go pc-3784))
          (3785 (cl:go pc-3785))
          (3786 (cl:go pc-3786))
          (3787 (cl:go pc-3787))
          (3788 (cl:go pc-3788))
          (3789 (cl:go pc-3789))
          (3790 (cl:go pc-3790))
          (3791 (cl:go pc-3791))
          (3792 (cl:go pc-3792))
          (3793 (cl:go pc-3793))
          (3794 (cl:go pc-3794))
          (3795 (cl:go pc-3795))
          (3796 (cl:go pc-3796))
          (3797 (cl:go pc-3797))
          (3798 (cl:go pc-3798))
          (3799 (cl:go pc-3799))
          (3800 (cl:go pc-3800))
          (3801 (cl:go pc-3801))
          (3802 (cl:go pc-3802))
          (3803 (cl:go pc-3803))
          (3804 (cl:go pc-3804))
          (3805 (cl:go pc-3805))
          (3806 (cl:go pc-3806))
          (3807 (cl:go pc-3807))
          (3808 (cl:go pc-3808))
          (3809 (cl:go pc-3809))
          (3810 (cl:go pc-3810))
          (3811 (cl:go pc-3811))
          (3812 (cl:go pc-3812))
          (3813 (cl:go pc-3813))
          (3814 (cl:go pc-3814))
          (3815 (cl:go pc-3815))
          (3816 (cl:go pc-3816))
          (3817 (cl:go pc-3817))
          (3818 (cl:go pc-3818))
          (3819 (cl:go pc-3819))
          (3820 (cl:go pc-3820))
          (3821 (cl:go pc-3821))
          (3822 (cl:go pc-3822))
          (3823 (cl:go pc-3823))
          (3824 (cl:go pc-3824))
          (3825 (cl:go pc-3825))
          (3826 (cl:go pc-3826))
          (3827 (cl:go pc-3827))
          (3828 (cl:go pc-3828))
          (3829 (cl:go pc-3829))
          (3830 (cl:go pc-3830))
          (3831 (cl:go pc-3831))
          (3832 (cl:go pc-3832))
          (3833 (cl:go pc-3833))
          (3834 (cl:go pc-3834))
          (3835 (cl:go pc-3835))
          (3836 (cl:go pc-3836))
          (3837 (cl:go pc-3837))
          (3838 (cl:go pc-3838))
          (3839 (cl:go pc-3839))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 4096)
        (cl:case pc
          (3840 (cl:go pc-3840))
          (3841 (cl:go pc-3841))
          (3842 (cl:go pc-3842))
          (3843 (cl:go pc-3843))
          (3844 (cl:go pc-3844))
          (3845 (cl:go pc-3845))
          (3846 (cl:go pc-3846))
          (3847 (cl:go pc-3847))
          (3848 (cl:go pc-3848))
          (3849 (cl:go pc-3849))
          (3850 (cl:go pc-3850))
          (3851 (cl:go pc-3851))
          (3852 (cl:go pc-3852))
          (3853 (cl:go pc-3853))
          (3854 (cl:go pc-3854))
          (3855 (cl:go pc-3855))
          (3856 (cl:go pc-3856))
          (3857 (cl:go pc-3857))
          (3858 (cl:go pc-3858))
          (3859 (cl:go pc-3859))
          (3860 (cl:go pc-3860))
          (3861 (cl:go pc-3861))
          (3862 (cl:go pc-3862))
          (3863 (cl:go pc-3863))
          (3864 (cl:go pc-3864))
          (3865 (cl:go pc-3865))
          (3866 (cl:go pc-3866))
          (3867 (cl:go pc-3867))
          (3868 (cl:go pc-3868))
          (3869 (cl:go pc-3869))
          (3870 (cl:go pc-3870))
          (3871 (cl:go pc-3871))
          (3872 (cl:go pc-3872))
          (3873 (cl:go pc-3873))
          (3874 (cl:go pc-3874))
          (3875 (cl:go pc-3875))
          (3876 (cl:go pc-3876))
          (3877 (cl:go pc-3877))
          (3878 (cl:go pc-3878))
          (3879 (cl:go pc-3879))
          (3880 (cl:go pc-3880))
          (3881 (cl:go pc-3881))
          (3882 (cl:go pc-3882))
          (3883 (cl:go pc-3883))
          (3884 (cl:go pc-3884))
          (3885 (cl:go pc-3885))
          (3886 (cl:go pc-3886))
          (3887 (cl:go pc-3887))
          (3888 (cl:go pc-3888))
          (3889 (cl:go pc-3889))
          (3890 (cl:go pc-3890))
          (3891 (cl:go pc-3891))
          (3892 (cl:go pc-3892))
          (3893 (cl:go pc-3893))
          (3894 (cl:go pc-3894))
          (3895 (cl:go pc-3895))
          (3896 (cl:go pc-3896))
          (3897 (cl:go pc-3897))
          (3898 (cl:go pc-3898))
          (3899 (cl:go pc-3899))
          (3900 (cl:go pc-3900))
          (3901 (cl:go pc-3901))
          (3902 (cl:go pc-3902))
          (3903 (cl:go pc-3903))
          (3904 (cl:go pc-3904))
          (3905 (cl:go pc-3905))
          (3906 (cl:go pc-3906))
          (3907 (cl:go pc-3907))
          (3908 (cl:go pc-3908))
          (3909 (cl:go pc-3909))
          (3910 (cl:go pc-3910))
          (3911 (cl:go pc-3911))
          (3912 (cl:go pc-3912))
          (3913 (cl:go pc-3913))
          (3914 (cl:go pc-3914))
          (3915 (cl:go pc-3915))
          (3916 (cl:go pc-3916))
          (3917 (cl:go pc-3917))
          (3918 (cl:go pc-3918))
          (3919 (cl:go pc-3919))
          (3920 (cl:go pc-3920))
          (3921 (cl:go pc-3921))
          (3922 (cl:go pc-3922))
          (3923 (cl:go pc-3923))
          (3924 (cl:go pc-3924))
          (3925 (cl:go pc-3925))
          (3926 (cl:go pc-3926))
          (3927 (cl:go pc-3927))
          (3928 (cl:go pc-3928))
          (3929 (cl:go pc-3929))
          (3930 (cl:go pc-3930))
          (3931 (cl:go pc-3931))
          (3932 (cl:go pc-3932))
          (3933 (cl:go pc-3933))
          (3934 (cl:go pc-3934))
          (3935 (cl:go pc-3935))
          (3936 (cl:go pc-3936))
          (3937 (cl:go pc-3937))
          (3938 (cl:go pc-3938))
          (3939 (cl:go pc-3939))
          (3940 (cl:go pc-3940))
          (3941 (cl:go pc-3941))
          (3942 (cl:go pc-3942))
          (3943 (cl:go pc-3943))
          (3944 (cl:go pc-3944))
          (3945 (cl:go pc-3945))
          (3946 (cl:go pc-3946))
          (3947 (cl:go pc-3947))
          (3948 (cl:go pc-3948))
          (3949 (cl:go pc-3949))
          (3950 (cl:go pc-3950))
          (3951 (cl:go pc-3951))
          (3952 (cl:go pc-3952))
          (3953 (cl:go pc-3953))
          (3954 (cl:go pc-3954))
          (3955 (cl:go pc-3955))
          (3956 (cl:go pc-3956))
          (3957 (cl:go pc-3957))
          (3958 (cl:go pc-3958))
          (3959 (cl:go pc-3959))
          (3960 (cl:go pc-3960))
          (3961 (cl:go pc-3961))
          (3962 (cl:go pc-3962))
          (3963 (cl:go pc-3963))
          (3964 (cl:go pc-3964))
          (3965 (cl:go pc-3965))
          (3966 (cl:go pc-3966))
          (3967 (cl:go pc-3967))
          (3968 (cl:go pc-3968))
          (3969 (cl:go pc-3969))
          (3970 (cl:go pc-3970))
          (3971 (cl:go pc-3971))
          (3972 (cl:go pc-3972))
          (3973 (cl:go pc-3973))
          (3974 (cl:go pc-3974))
          (3975 (cl:go pc-3975))
          (3976 (cl:go pc-3976))
          (3977 (cl:go pc-3977))
          (3978 (cl:go pc-3978))
          (3979 (cl:go pc-3979))
          (3980 (cl:go pc-3980))
          (3981 (cl:go pc-3981))
          (3982 (cl:go pc-3982))
          (3983 (cl:go pc-3983))
          (3984 (cl:go pc-3984))
          (3985 (cl:go pc-3985))
          (3986 (cl:go pc-3986))
          (3987 (cl:go pc-3987))
          (3988 (cl:go pc-3988))
          (3989 (cl:go pc-3989))
          (3990 (cl:go pc-3990))
          (3991 (cl:go pc-3991))
          (3992 (cl:go pc-3992))
          (3993 (cl:go pc-3993))
          (3994 (cl:go pc-3994))
          (3995 (cl:go pc-3995))
          (3996 (cl:go pc-3996))
          (3997 (cl:go pc-3997))
          (3998 (cl:go pc-3998))
          (3999 (cl:go pc-3999))
          (4000 (cl:go pc-4000))
          (4001 (cl:go pc-4001))
          (4002 (cl:go pc-4002))
          (4003 (cl:go pc-4003))
          (4004 (cl:go pc-4004))
          (4005 (cl:go pc-4005))
          (4006 (cl:go pc-4006))
          (4007 (cl:go pc-4007))
          (4008 (cl:go pc-4008))
          (4009 (cl:go pc-4009))
          (4010 (cl:go pc-4010))
          (4011 (cl:go pc-4011))
          (4012 (cl:go pc-4012))
          (4013 (cl:go pc-4013))
          (4014 (cl:go pc-4014))
          (4015 (cl:go pc-4015))
          (4016 (cl:go pc-4016))
          (4017 (cl:go pc-4017))
          (4018 (cl:go pc-4018))
          (4019 (cl:go pc-4019))
          (4020 (cl:go pc-4020))
          (4021 (cl:go pc-4021))
          (4022 (cl:go pc-4022))
          (4023 (cl:go pc-4023))
          (4024 (cl:go pc-4024))
          (4025 (cl:go pc-4025))
          (4026 (cl:go pc-4026))
          (4027 (cl:go pc-4027))
          (4028 (cl:go pc-4028))
          (4029 (cl:go pc-4029))
          (4030 (cl:go pc-4030))
          (4031 (cl:go pc-4031))
          (4032 (cl:go pc-4032))
          (4033 (cl:go pc-4033))
          (4034 (cl:go pc-4034))
          (4035 (cl:go pc-4035))
          (4036 (cl:go pc-4036))
          (4037 (cl:go pc-4037))
          (4038 (cl:go pc-4038))
          (4039 (cl:go pc-4039))
          (4040 (cl:go pc-4040))
          (4041 (cl:go pc-4041))
          (4042 (cl:go pc-4042))
          (4043 (cl:go pc-4043))
          (4044 (cl:go pc-4044))
          (4045 (cl:go pc-4045))
          (4046 (cl:go pc-4046))
          (4047 (cl:go pc-4047))
          (4048 (cl:go pc-4048))
          (4049 (cl:go pc-4049))
          (4050 (cl:go pc-4050))
          (4051 (cl:go pc-4051))
          (4052 (cl:go pc-4052))
          (4053 (cl:go pc-4053))
          (4054 (cl:go pc-4054))
          (4055 (cl:go pc-4055))
          (4056 (cl:go pc-4056))
          (4057 (cl:go pc-4057))
          (4058 (cl:go pc-4058))
          (4059 (cl:go pc-4059))
          (4060 (cl:go pc-4060))
          (4061 (cl:go pc-4061))
          (4062 (cl:go pc-4062))
          (4063 (cl:go pc-4063))
          (4064 (cl:go pc-4064))
          (4065 (cl:go pc-4065))
          (4066 (cl:go pc-4066))
          (4067 (cl:go pc-4067))
          (4068 (cl:go pc-4068))
          (4069 (cl:go pc-4069))
          (4070 (cl:go pc-4070))
          (4071 (cl:go pc-4071))
          (4072 (cl:go pc-4072))
          (4073 (cl:go pc-4073))
          (4074 (cl:go pc-4074))
          (4075 (cl:go pc-4075))
          (4076 (cl:go pc-4076))
          (4077 (cl:go pc-4077))
          (4078 (cl:go pc-4078))
          (4079 (cl:go pc-4079))
          (4080 (cl:go pc-4080))
          (4081 (cl:go pc-4081))
          (4082 (cl:go pc-4082))
          (4083 (cl:go pc-4083))
          (4084 (cl:go pc-4084))
          (4085 (cl:go pc-4085))
          (4086 (cl:go pc-4086))
          (4087 (cl:go pc-4087))
          (4088 (cl:go pc-4088))
          (4089 (cl:go pc-4089))
          (4090 (cl:go pc-4090))
          (4091 (cl:go pc-4091))
          (4092 (cl:go pc-4092))
          (4093 (cl:go pc-4093))
          (4094 (cl:go pc-4094))
          (4095 (cl:go pc-4095))
          (cl:t (cl:go chunk-exit))))
       (cl:t (cl:go chunk-exit)))
     pc-0
       (cl:push env stack)
       (cl:setf pc 1)
     pc-1
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%make-hash-table| env))
       (cl:setf pc 2)
     pc-2
       (cl:setf argl cl:nil)
       (cl:setf pc 3)
     pc-3
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4)
     pc-4
       (cl:when flag (cl:setf pc 19) (cl:go pc-19))
     pc-5
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6)
     pc-6
       (cl:when flag (cl:setf pc 12) (cl:go pc-12))
     pc-7
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 8)
     pc-8
       (cl:when flag (cl:setf pc 17) (cl:go pc-17))
     pc-9
       (cl:setf continue (cl:cons '|compilation-unit| 20))
       (cl:setf pc 10)
     pc-10
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 11)
     pc-11
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-12
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 13)
     pc-13
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 14)
     pc-14
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 15)
     pc-15
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 16)
     pc-16
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-17
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 18)
     pc-18
       (cl:setf pc 20) (cl:go pc-20)
     pc-19
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 20)
     pc-20
       (cl:setf env (cl:pop stack))
       (cl:setf pc 21)
     pc-21
       (cl:funcall (get-operation '|define-variable!|) '|*source-locations*| val env)
       (cl:setf pc 22)
     pc-22
       (cl:setf val val)
       (cl:setf pc 23)
     pc-23
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 24)
     pc-24
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 25)
     pc-25
       (cl:funcall (get-operation '|define-variable!|) '|*source-file-name*| val env)
       (cl:setf pc 26)
     pc-26
       (cl:setf val val)
       (cl:setf pc 27)
     pc-27
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 28)
     pc-28
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 29)
     pc-29
       (cl:funcall (get-operation '|define-variable!|) '|*current-source-location*| val env)
       (cl:setf pc 30)
     pc-30
       (cl:setf val val)
       (cl:setf pc 31)
     pc-31
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 32)
     pc-32
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 34 env))
       (cl:setf pc 33)
     pc-33
       (cl:setf pc 135) (cl:go pc-135)
     pc-34
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 35)
     pc-35
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|expr|) argl env 0))
       (cl:setf pc 36)
     pc-36
       (cl:setf val "Compile a single expression and return a compiled unit value.")
       (cl:setf pc 37)
     pc-37
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 38)
     pc-38
       (cl:funcall (get-operation '|set-variable-value!|) '|*current-source-location*| val env)
       (cl:setf pc 39)
     pc-39
       (cl:setf val val)
       (cl:setf pc 40)
     pc-40
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 42 env))
       (cl:setf pc 41)
     pc-41
       (cl:setf pc 89) (cl:go pc-89)
     pc-42
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 43)
     pc-43
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|compiled|) argl env 0))
       (cl:setf pc 44)
     pc-44
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 45)
     pc-45
       (cl:push continue stack)
       (cl:setf pc 46)
     pc-46
       (cl:push proc stack)
       (cl:setf pc 47)
     pc-47
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|mc-instructions| env))
       (cl:setf pc 48)
     pc-48
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 49)
     pc-49
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 50)
     pc-50
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 51)
     pc-51
       (cl:when flag (cl:setf pc 66) (cl:go pc-66))
     pc-52
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 53)
     pc-53
       (cl:when flag (cl:setf pc 59) (cl:go pc-59))
     pc-54
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 55)
     pc-55
       (cl:when flag (cl:setf pc 64) (cl:go pc-64))
     pc-56
       (cl:setf continue (cl:cons '|compilation-unit| 67))
       (cl:setf pc 57)
     pc-57
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 58)
     pc-58
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-59
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 60)
     pc-60
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 61)
     pc-61
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 62)
     pc-62
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 63)
     pc-63
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-64
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 65)
     pc-65
       (cl:setf pc 67) (cl:go pc-67)
     pc-66
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 67)
     pc-67
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 68)
     pc-68
       (cl:setf val '|compiled-unit|)
       (cl:setf pc 69)
     pc-69
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 70)
     pc-70
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 71)
     pc-71
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 72)
     pc-72
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 73)
     pc-73
       (cl:when flag (cl:setf pc 87) (cl:go pc-87))
     pc-74
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 75)
     pc-75
       (cl:when flag (cl:setf pc 80) (cl:go pc-80))
     pc-76
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 77)
     pc-77
       (cl:when flag (cl:setf pc 85) (cl:go pc-85))
     pc-78
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 79)
     pc-79
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-80
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 81)
     pc-81
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 82)
     pc-82
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 83)
     pc-83
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 84)
     pc-84
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-85
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 86)
     pc-86
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-87
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 88)
     pc-88
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-89
       (cl:push continue stack)
       (cl:setf pc 90)
     pc-90
       (cl:push proc stack)
       (cl:setf pc 91)
     pc-91
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|mc-compile| env))
       (cl:setf pc 92)
     pc-92
       (cl:setf val '|next|)
       (cl:setf pc 93)
     pc-93
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 94)
     pc-94
       (cl:setf val '|val|)
       (cl:setf pc 95)
     pc-95
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 96)
     pc-96
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 97)
     pc-97
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 98)
     pc-98
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 99)
     pc-99
       (cl:when flag (cl:setf pc 114) (cl:go pc-114))
     pc-100
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 101)
     pc-101
       (cl:when flag (cl:setf pc 107) (cl:go pc-107))
     pc-102
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 103)
     pc-103
       (cl:when flag (cl:setf pc 112) (cl:go pc-112))
     pc-104
       (cl:setf continue (cl:cons '|compilation-unit| 115))
       (cl:setf pc 105)
     pc-105
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 106)
     pc-106
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-107
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 108)
     pc-108
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 109)
     pc-109
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 110)
     pc-110
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 111)
     pc-111
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-112
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 113)
     pc-113
       (cl:setf pc 115) (cl:go pc-115)
     pc-114
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 115)
     pc-115
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 116)
     pc-116
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 117)
     pc-117
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 118)
     pc-118
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 119)
     pc-119
       (cl:when flag (cl:setf pc 133) (cl:go pc-133))
     pc-120
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 121)
     pc-121
       (cl:when flag (cl:setf pc 126) (cl:go pc-126))
     pc-122
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 123)
     pc-123
       (cl:when flag (cl:setf pc 131) (cl:go pc-131))
     pc-124
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 125)
     pc-125
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-126
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 127)
     pc-127
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 128)
     pc-128
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 129)
     pc-129
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 130)
     pc-130
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-131
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 132)
     pc-132
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-133
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 134)
     pc-134
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-135
       (cl:funcall (get-operation '|define-variable!|) '|compile-form| val env)
       (cl:setf pc 136)
     pc-136
       (cl:setf val val)
       (cl:setf pc 137)
     pc-137
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 138)
     pc-138
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 140 env))
       (cl:setf pc 139)
     pc-139
       (cl:setf pc 218) (cl:go pc-218)
     pc-140
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 141)
     pc-141
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|obj|) argl env 0))
       (cl:setf pc 142)
     pc-142
       (cl:setf val "Return #t if OBJ is a compiled unit.")
       (cl:setf pc 143)
     pc-143
       (cl:push continue stack)
       (cl:setf pc 144)
     pc-144
       (cl:push env stack)
       (cl:setf pc 145)
     pc-145
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 146)
     pc-146
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 147)
     pc-147
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 148)
     pc-148
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 149)
     pc-149
       (cl:when flag (cl:setf pc 164) (cl:go pc-164))
     pc-150
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 151)
     pc-151
       (cl:when flag (cl:setf pc 157) (cl:go pc-157))
     pc-152
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 153)
     pc-153
       (cl:when flag (cl:setf pc 162) (cl:go pc-162))
     pc-154
       (cl:setf continue (cl:cons '|compilation-unit| 165))
       (cl:setf pc 155)
     pc-155
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 156)
     pc-156
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-157
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 158)
     pc-158
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 159)
     pc-159
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 160)
     pc-160
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 161)
     pc-161
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-162
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 163)
     pc-163
       (cl:setf pc 165) (cl:go pc-165)
     pc-164
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 165)
     pc-165
       (cl:setf env (cl:pop stack))
       (cl:setf pc 166)
     pc-166
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 167)
     pc-167
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 168)
     pc-168
       (cl:when flag (cl:setf pc 216) (cl:go pc-216))
     pc-169
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 170)
     pc-170
       (cl:push continue stack)
       (cl:setf pc 171)
     pc-171
       (cl:push proc stack)
       (cl:setf pc 172)
     pc-172
       (cl:setf val '|compiled-unit|)
       (cl:setf pc 173)
     pc-173
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 174)
     pc-174
       (cl:push argl stack)
       (cl:setf pc 175)
     pc-175
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 176)
     pc-176
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 177)
     pc-177
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 178)
     pc-178
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 179)
     pc-179
       (cl:when flag (cl:setf pc 194) (cl:go pc-194))
     pc-180
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 181)
     pc-181
       (cl:when flag (cl:setf pc 187) (cl:go pc-187))
     pc-182
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 183)
     pc-183
       (cl:when flag (cl:setf pc 192) (cl:go pc-192))
     pc-184
       (cl:setf continue (cl:cons '|compilation-unit| 195))
       (cl:setf pc 185)
     pc-185
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 186)
     pc-186
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-187
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 188)
     pc-188
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 189)
     pc-189
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 190)
     pc-190
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 191)
     pc-191
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-192
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 193)
     pc-193
       (cl:setf pc 195) (cl:go pc-195)
     pc-194
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 195)
     pc-195
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 196)
     pc-196
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 197)
     pc-197
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 198)
     pc-198
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 199)
     pc-199
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 200)
     pc-200
       (cl:when flag (cl:setf pc 214) (cl:go pc-214))
     pc-201
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 202)
     pc-202
       (cl:when flag (cl:setf pc 207) (cl:go pc-207))
     pc-203
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 204)
     pc-204
       (cl:when flag (cl:setf pc 212) (cl:go pc-212))
     pc-205
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 206)
     pc-206
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-207
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 208)
     pc-208
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 209)
     pc-209
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 210)
     pc-210
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 211)
     pc-211
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-212
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 213)
     pc-213
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-214
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 215)
     pc-215
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-216
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 217)
     pc-217
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-218
       (cl:funcall (get-operation '|define-variable!|) '|compiled-unit?| val env)
       (cl:setf pc 219)
     pc-219
       (cl:setf val val)
       (cl:setf pc 220)
     pc-220
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 221)
     pc-221
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 223 env))
       (cl:setf pc 222)
     pc-222
       (cl:setf pc 246) (cl:go pc-246)
     pc-223
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 224)
     pc-224
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|unit|) argl env 0))
       (cl:setf pc 225)
     pc-225
       (cl:setf val "Return the flat instruction list from a compiled unit.")
       (cl:setf pc 226)
     pc-226
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 227)
     pc-227
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 228)
     pc-228
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 229)
     pc-229
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 230)
     pc-230
       (cl:when flag (cl:setf pc 244) (cl:go pc-244))
     pc-231
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 232)
     pc-232
       (cl:when flag (cl:setf pc 237) (cl:go pc-237))
     pc-233
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 234)
     pc-234
       (cl:when flag (cl:setf pc 242) (cl:go pc-242))
     pc-235
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 236)
     pc-236
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-237
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 238)
     pc-238
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 239)
     pc-239
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 240)
     pc-240
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 241)
     pc-241
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-242
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 243)
     pc-243
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-244
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 245)
     pc-245
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-246
       (cl:funcall (get-operation '|define-variable!|) '|compiled-unit-instructions| val env)
       (cl:setf pc 247)
     pc-247
       (cl:setf val val)
       (cl:setf pc 248)
     pc-248
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 249)
     pc-249
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 251 env))
       (cl:setf pc 250)
     pc-250
       (cl:setf pc 341) (cl:go pc-341)
     pc-251
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 252)
     pc-252
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|unit|) argl env 0))
       (cl:setf pc 253)
     pc-253
       (cl:setf val "Assemble and execute a compiled unit, returning the result.")
       (cl:setf pc 254)
     pc-254
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 256 env))
       (cl:setf pc 255)
     pc-255
       (cl:setf pc 278) (cl:go pc-278)
     pc-256
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 257)
     pc-257
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|start-pc|) argl env 0))
       (cl:setf pc 258)
     pc-258
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|execute-from-pc| env))
       (cl:setf pc 259)
     pc-259
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 260)
     pc-260
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 261)
     pc-261
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 262)
     pc-262
       (cl:when flag (cl:setf pc 276) (cl:go pc-276))
     pc-263
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 264)
     pc-264
       (cl:when flag (cl:setf pc 269) (cl:go pc-269))
     pc-265
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 266)
     pc-266
       (cl:when flag (cl:setf pc 274) (cl:go pc-274))
     pc-267
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 268)
     pc-268
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-269
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 270)
     pc-270
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 271)
     pc-271
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 272)
     pc-272
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 273)
     pc-273
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-274
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 275)
     pc-275
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-276
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 277)
     pc-277
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-278
       (cl:push continue stack)
       (cl:setf pc 279)
     pc-279
       (cl:push proc stack)
       (cl:setf pc 280)
     pc-280
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|assemble-into-global| env))
       (cl:setf pc 281)
     pc-281
       (cl:push proc stack)
       (cl:setf pc 282)
     pc-282
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|compiled-unit-instructions| env))
       (cl:setf pc 283)
     pc-283
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 284)
     pc-284
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 285)
     pc-285
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 286)
     pc-286
       (cl:when flag (cl:setf pc 301) (cl:go pc-301))
     pc-287
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 288)
     pc-288
       (cl:when flag (cl:setf pc 294) (cl:go pc-294))
     pc-289
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 290)
     pc-290
       (cl:when flag (cl:setf pc 299) (cl:go pc-299))
     pc-291
       (cl:setf continue (cl:cons '|compilation-unit| 302))
       (cl:setf pc 292)
     pc-292
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 293)
     pc-293
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-294
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 295)
     pc-295
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 296)
     pc-296
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 297)
     pc-297
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 298)
     pc-298
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-299
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 300)
     pc-300
       (cl:setf pc 302) (cl:go pc-302)
     pc-301
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 302)
     pc-302
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 303)
     pc-303
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 304)
     pc-304
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 305)
     pc-305
       (cl:when flag (cl:setf pc 320) (cl:go pc-320))
     pc-306
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 307)
     pc-307
       (cl:when flag (cl:setf pc 313) (cl:go pc-313))
     pc-308
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 309)
     pc-309
       (cl:when flag (cl:setf pc 318) (cl:go pc-318))
     pc-310
       (cl:setf continue (cl:cons '|compilation-unit| 321))
       (cl:setf pc 311)
     pc-311
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 312)
     pc-312
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-313
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 314)
     pc-314
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 315)
     pc-315
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 316)
     pc-316
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 317)
     pc-317
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-318
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 319)
     pc-319
       (cl:setf pc 321) (cl:go pc-321)
     pc-320
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 321)
     pc-321
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 322)
     pc-322
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 323)
     pc-323
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 324)
     pc-324
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 325)
     pc-325
       (cl:when flag (cl:setf pc 339) (cl:go pc-339))
     pc-326
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 327)
     pc-327
       (cl:when flag (cl:setf pc 332) (cl:go pc-332))
     pc-328
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 329)
     pc-329
       (cl:when flag (cl:setf pc 337) (cl:go pc-337))
     pc-330
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 331)
     pc-331
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-332
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 333)
     pc-333
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 334)
     pc-334
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 335)
     pc-335
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 336)
     pc-336
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-337
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 338)
     pc-338
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-339
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 340)
     pc-340
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-341
       (cl:funcall (get-operation '|define-variable!|) '|execute| val env)
       (cl:setf pc 342)
     pc-342
       (cl:setf val val)
       (cl:setf pc 343)
     pc-343
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 344)
     pc-344
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 346 env))
       (cl:setf pc 345)
     pc-345
       (cl:setf pc 575) (cl:go pc-575)
     pc-346
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 347)
     pc-347
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|str| |port|) argl env 0))
       (cl:setf pc 348)
     pc-348
       (cl:setf val "Write each character of STR to PORT.")
       (cl:setf pc 349)
     pc-349
       (cl:push continue stack)
       (cl:setf pc 350)
     pc-350
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 352 env))
       (cl:setf pc 351)
     pc-351
       (cl:setf pc 534) (cl:go pc-534)
     pc-352
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 353)
     pc-353
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|loop|) argl env 0))
       (cl:setf pc 354)
     pc-354
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 356 env))
       (cl:setf pc 355)
     pc-355
       (cl:setf pc 363) (cl:go pc-363)
     pc-356
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 357)
     pc-357
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|g178|) argl env 0))
       (cl:setf pc 358)
     pc-358
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 359)
     pc-359
       (cl:funcall (get-operation '|lexical-set!|) 1 0 val env)
       (cl:setf pc 360)
     pc-360
       (cl:setf val val)
       (cl:setf pc 361)
     pc-361
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 362)
     pc-362
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-363
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 365 env))
       (cl:setf pc 364)
     pc-364
       (cl:setf pc 516) (cl:go pc-516)
     pc-365
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 366)
     pc-366
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|i|) argl env 0))
       (cl:setf pc 367)
     pc-367
       (cl:push continue stack)
       (cl:setf pc 368)
     pc-368
       (cl:push env stack)
       (cl:setf pc 369)
     pc-369
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|<| env))
       (cl:setf pc 370)
     pc-370
       (cl:push proc stack)
       (cl:setf pc 371)
     pc-371
       (cl:push env stack)
       (cl:setf pc 372)
     pc-372
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string-length| env))
       (cl:setf pc 373)
     pc-373
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 374)
     pc-374
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 375)
     pc-375
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 376)
     pc-376
       (cl:when flag (cl:setf pc 391) (cl:go pc-391))
     pc-377
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 378)
     pc-378
       (cl:when flag (cl:setf pc 384) (cl:go pc-384))
     pc-379
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 380)
     pc-380
       (cl:when flag (cl:setf pc 389) (cl:go pc-389))
     pc-381
       (cl:setf continue (cl:cons '|compilation-unit| 392))
       (cl:setf pc 382)
     pc-382
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 383)
     pc-383
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-384
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 385)
     pc-385
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 386)
     pc-386
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 387)
     pc-387
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 388)
     pc-388
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-389
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 390)
     pc-390
       (cl:setf pc 392) (cl:go pc-392)
     pc-391
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 392)
     pc-392
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 393)
     pc-393
       (cl:setf env (cl:pop stack))
       (cl:setf pc 394)
     pc-394
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 395)
     pc-395
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 396)
     pc-396
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 397)
     pc-397
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 398)
     pc-398
       (cl:when flag (cl:setf pc 413) (cl:go pc-413))
     pc-399
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 400)
     pc-400
       (cl:when flag (cl:setf pc 406) (cl:go pc-406))
     pc-401
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 402)
     pc-402
       (cl:when flag (cl:setf pc 411) (cl:go pc-411))
     pc-403
       (cl:setf continue (cl:cons '|compilation-unit| 414))
       (cl:setf pc 404)
     pc-404
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 405)
     pc-405
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-406
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 407)
     pc-407
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 408)
     pc-408
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 409)
     pc-409
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 410)
     pc-410
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-411
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 412)
     pc-412
       (cl:setf pc 414) (cl:go pc-414)
     pc-413
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 414)
     pc-414
       (cl:setf env (cl:pop stack))
       (cl:setf pc 415)
     pc-415
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 416)
     pc-416
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 417)
     pc-417
       (cl:when flag (cl:setf pc 514) (cl:go pc-514))
     pc-418
       (cl:push continue stack)
       (cl:setf pc 419)
     pc-419
       (cl:push env stack)
       (cl:setf pc 420)
     pc-420
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-char| env))
       (cl:setf pc 421)
     pc-421
       (cl:push proc stack)
       (cl:setf pc 422)
     pc-422
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 1 env))
       (cl:setf pc 423)
     pc-423
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 424)
     pc-424
       (cl:push argl stack)
       (cl:setf pc 425)
     pc-425
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string-ref| env))
       (cl:setf pc 426)
     pc-426
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 427)
     pc-427
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 428)
     pc-428
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 429)
     pc-429
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 430)
     pc-430
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 431)
     pc-431
       (cl:when flag (cl:setf pc 446) (cl:go pc-446))
     pc-432
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 433)
     pc-433
       (cl:when flag (cl:setf pc 439) (cl:go pc-439))
     pc-434
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 435)
     pc-435
       (cl:when flag (cl:setf pc 444) (cl:go pc-444))
     pc-436
       (cl:setf continue (cl:cons '|compilation-unit| 447))
       (cl:setf pc 437)
     pc-437
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 438)
     pc-438
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-439
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 440)
     pc-440
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 441)
     pc-441
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 442)
     pc-442
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 443)
     pc-443
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-444
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 445)
     pc-445
       (cl:setf pc 447) (cl:go pc-447)
     pc-446
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 447)
     pc-447
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 448)
     pc-448
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 449)
     pc-449
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 450)
     pc-450
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 451)
     pc-451
       (cl:when flag (cl:setf pc 466) (cl:go pc-466))
     pc-452
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 453)
     pc-453
       (cl:when flag (cl:setf pc 459) (cl:go pc-459))
     pc-454
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 455)
     pc-455
       (cl:when flag (cl:setf pc 464) (cl:go pc-464))
     pc-456
       (cl:setf continue (cl:cons '|compilation-unit| 467))
       (cl:setf pc 457)
     pc-457
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 458)
     pc-458
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-459
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 460)
     pc-460
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 461)
     pc-461
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 462)
     pc-462
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 463)
     pc-463
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-464
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 465)
     pc-465
       (cl:setf pc 467) (cl:go pc-467)
     pc-466
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 467)
     pc-467
       (cl:setf env (cl:pop stack))
       (cl:setf pc 468)
     pc-468
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 469)
     pc-469
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 470)
     pc-470
       (cl:push continue stack)
       (cl:setf pc 471)
     pc-471
       (cl:push proc stack)
       (cl:setf pc 472)
     pc-472
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|+| env))
       (cl:setf pc 473)
     pc-473
       (cl:setf val 1)
       (cl:setf pc 474)
     pc-474
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 475)
     pc-475
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 476)
     pc-476
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 477)
     pc-477
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 478)
     pc-478
       (cl:when flag (cl:setf pc 493) (cl:go pc-493))
     pc-479
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 480)
     pc-480
       (cl:when flag (cl:setf pc 486) (cl:go pc-486))
     pc-481
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 482)
     pc-482
       (cl:when flag (cl:setf pc 491) (cl:go pc-491))
     pc-483
       (cl:setf continue (cl:cons '|compilation-unit| 494))
       (cl:setf pc 484)
     pc-484
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 485)
     pc-485
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-486
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 487)
     pc-487
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 488)
     pc-488
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 489)
     pc-489
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 490)
     pc-490
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-491
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 492)
     pc-492
       (cl:setf pc 494) (cl:go pc-494)
     pc-493
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 494)
     pc-494
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 495)
     pc-495
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 496)
     pc-496
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 497)
     pc-497
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 498)
     pc-498
       (cl:when flag (cl:setf pc 512) (cl:go pc-512))
     pc-499
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 500)
     pc-500
       (cl:when flag (cl:setf pc 505) (cl:go pc-505))
     pc-501
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 502)
     pc-502
       (cl:when flag (cl:setf pc 510) (cl:go pc-510))
     pc-503
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 504)
     pc-504
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-505
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 506)
     pc-506
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 507)
     pc-507
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 508)
     pc-508
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 509)
     pc-509
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-510
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 511)
     pc-511
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-512
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 513)
     pc-513
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-514
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 515)
     pc-515
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-516
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 517)
     pc-517
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 518)
     pc-518
       (cl:when flag (cl:setf pc 532) (cl:go pc-532))
     pc-519
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 520)
     pc-520
       (cl:when flag (cl:setf pc 525) (cl:go pc-525))
     pc-521
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 522)
     pc-522
       (cl:when flag (cl:setf pc 530) (cl:go pc-530))
     pc-523
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 524)
     pc-524
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-525
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 526)
     pc-526
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 527)
     pc-527
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 528)
     pc-528
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 529)
     pc-529
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-530
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 531)
     pc-531
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-532
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 533)
     pc-533
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-534
       (cl:setf val cl:nil)
       (cl:setf pc 535)
     pc-535
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 536)
     pc-536
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 537)
     pc-537
       (cl:when flag (cl:setf pc 554) (cl:go pc-554))
     pc-538
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 539)
     pc-539
       (cl:when flag (cl:setf pc 547) (cl:go pc-547))
     pc-540
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 541)
     pc-541
       (cl:when flag (cl:setf pc 552) (cl:go pc-552))
     pc-542
       (cl:setf continue (cl:cons '|compilation-unit| 545))
       (cl:setf pc 543)
     pc-543
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 544)
     pc-544
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-545
       (cl:setf proc val)
       (cl:setf pc 546)
     pc-546
       (cl:setf pc 555) (cl:go pc-555)
     pc-547
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 548)
     pc-548
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 549)
     pc-549
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 550)
     pc-550
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 551)
     pc-551
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-552
       (cl:setf proc (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 553)
     pc-553
       (cl:setf pc 555) (cl:go pc-555)
     pc-554
       (cl:setf proc (cl:funcall (get-operation '|apply-primitive-procedure|) proc argl))
       (cl:setf pc 555)
     pc-555
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 556)
     pc-556
       (cl:setf val 0)
       (cl:setf pc 557)
     pc-557
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 558)
     pc-558
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 559)
     pc-559
       (cl:when flag (cl:setf pc 573) (cl:go pc-573))
     pc-560
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 561)
     pc-561
       (cl:when flag (cl:setf pc 566) (cl:go pc-566))
     pc-562
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 563)
     pc-563
       (cl:when flag (cl:setf pc 571) (cl:go pc-571))
     pc-564
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 565)
     pc-565
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-566
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 567)
     pc-567
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 568)
     pc-568
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 569)
     pc-569
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 570)
     pc-570
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-571
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 572)
     pc-572
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-573
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 574)
     pc-574
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-575
       (cl:funcall (get-operation '|define-variable!|) '|write-string-to-port| val env)
       (cl:setf pc 576)
     pc-576
       (cl:setf val val)
       (cl:setf pc 577)
     pc-577
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 578)
     pc-578
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 580 env))
       (cl:setf pc 579)
     pc-579
       (cl:setf pc 585) (cl:go pc-585)
     pc-580
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 581)
     pc-581
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|instrs|) argl env 0))
       (cl:setf pc 582)
     pc-582
       (cl:setf val "Rename gensym labels — currently identity (renaming deferred to golden tests).")
       (cl:setf pc 583)
     pc-583
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 584)
     pc-584
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-585
       (cl:funcall (get-operation '|define-variable!|) '|rename-labels| val env)
       (cl:setf pc 586)
     pc-586
       (cl:setf val val)
       (cl:setf pc 587)
     pc-587
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 588)
     pc-588
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 590 env))
       (cl:setf pc 589)
     pc-589
       (cl:setf pc 1013) (cl:go pc-1013)
     pc-590
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 591)
     pc-591
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|instrs| |port|) argl env 0))
       (cl:setf pc 592)
     pc-592
       (cl:setf val "Write a flat instruction list to PORT, one instruction/label per line.")
       (cl:setf pc 593)
     pc-593
       (cl:push continue stack)
       (cl:setf pc 594)
     pc-594
       (cl:push env stack)
       (cl:setf pc 595)
     pc-595
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-char| env))
       (cl:setf pc 596)
     pc-596
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 597)
     pc-597
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 598)
     pc-598
       (cl:setf val #\()
       (cl:setf pc 599)
     pc-599
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 600)
     pc-600
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 601)
     pc-601
       (cl:when flag (cl:setf pc 616) (cl:go pc-616))
     pc-602
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 603)
     pc-603
       (cl:when flag (cl:setf pc 609) (cl:go pc-609))
     pc-604
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 605)
     pc-605
       (cl:when flag (cl:setf pc 614) (cl:go pc-614))
     pc-606
       (cl:setf continue (cl:cons '|compilation-unit| 617))
       (cl:setf pc 607)
     pc-607
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 608)
     pc-608
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-609
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 610)
     pc-610
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 611)
     pc-611
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 612)
     pc-612
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 613)
     pc-613
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-614
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 615)
     pc-615
       (cl:setf pc 617) (cl:go pc-617)
     pc-616
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 617)
     pc-617
       (cl:setf env (cl:pop stack))
       (cl:setf pc 618)
     pc-618
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 619)
     pc-619
       (cl:push continue stack)
       (cl:setf pc 620)
     pc-620
       (cl:push env stack)
       (cl:setf pc 621)
     pc-621
       (cl:push env stack)
       (cl:setf pc 622)
     pc-622
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 624 env))
       (cl:setf pc 623)
     pc-623
       (cl:setf pc 920) (cl:go pc-920)
     pc-624
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 625)
     pc-625
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|loop|) argl env 0))
       (cl:setf pc 626)
     pc-626
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 628 env))
       (cl:setf pc 627)
     pc-627
       (cl:setf pc 635) (cl:go pc-635)
     pc-628
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 629)
     pc-629
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|g179|) argl env 0))
       (cl:setf pc 630)
     pc-630
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 631)
     pc-631
       (cl:funcall (get-operation '|lexical-set!|) 1 0 val env)
       (cl:setf pc 632)
     pc-632
       (cl:setf val val)
       (cl:setf pc 633)
     pc-633
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 634)
     pc-634
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-635
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 637 env))
       (cl:setf pc 636)
     pc-636
       (cl:setf pc 902) (cl:go pc-902)
     pc-637
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 638)
     pc-638
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|items| |first?|) argl env 0))
       (cl:setf pc 639)
     pc-639
       (cl:push continue stack)
       (cl:setf pc 640)
     pc-640
       (cl:push env stack)
       (cl:setf pc 641)
     pc-641
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 642)
     pc-642
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 643)
     pc-643
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 644)
     pc-644
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 645)
     pc-645
       (cl:when flag (cl:setf pc 660) (cl:go pc-660))
     pc-646
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 647)
     pc-647
       (cl:when flag (cl:setf pc 653) (cl:go pc-653))
     pc-648
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 649)
     pc-649
       (cl:when flag (cl:setf pc 658) (cl:go pc-658))
     pc-650
       (cl:setf continue (cl:cons '|compilation-unit| 661))
       (cl:setf pc 651)
     pc-651
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 652)
     pc-652
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-653
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 654)
     pc-654
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 655)
     pc-655
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 656)
     pc-656
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 657)
     pc-657
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-658
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 659)
     pc-659
       (cl:setf pc 661) (cl:go pc-661)
     pc-660
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 661)
     pc-661
       (cl:setf env (cl:pop stack))
       (cl:setf pc 662)
     pc-662
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 663)
     pc-663
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 664)
     pc-664
       (cl:when flag (cl:setf pc 900) (cl:go pc-900))
     pc-665
       (cl:push continue stack)
       (cl:setf pc 666)
     pc-666
       (cl:push env stack)
       (cl:setf pc 667)
     pc-667
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 668)
     pc-668
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 669)
     pc-669
       (cl:when flag (cl:setf pc 737) (cl:go pc-737))
     pc-670
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-string-to-port| env))
       (cl:setf pc 671)
     pc-671
       (cl:push proc stack)
       (cl:setf pc 672)
     pc-672
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 1 env))
       (cl:setf pc 673)
     pc-673
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 674)
     pc-674
       (cl:push argl stack)
       (cl:setf pc 675)
     pc-675
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-to-string-flat| env))
       (cl:setf pc 676)
     pc-676
       (cl:push proc stack)
       (cl:setf pc 677)
     pc-677
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 678)
     pc-678
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 679)
     pc-679
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 680)
     pc-680
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 681)
     pc-681
       (cl:when flag (cl:setf pc 696) (cl:go pc-696))
     pc-682
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 683)
     pc-683
       (cl:when flag (cl:setf pc 689) (cl:go pc-689))
     pc-684
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 685)
     pc-685
       (cl:when flag (cl:setf pc 694) (cl:go pc-694))
     pc-686
       (cl:setf continue (cl:cons '|compilation-unit| 697))
       (cl:setf pc 687)
     pc-687
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 688)
     pc-688
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-689
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 690)
     pc-690
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 691)
     pc-691
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 692)
     pc-692
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 693)
     pc-693
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-694
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 695)
     pc-695
       (cl:setf pc 697) (cl:go pc-697)
     pc-696
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 697)
     pc-697
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 698)
     pc-698
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 699)
     pc-699
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 700)
     pc-700
       (cl:when flag (cl:setf pc 715) (cl:go pc-715))
     pc-701
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 702)
     pc-702
       (cl:when flag (cl:setf pc 708) (cl:go pc-708))
     pc-703
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 704)
     pc-704
       (cl:when flag (cl:setf pc 713) (cl:go pc-713))
     pc-705
       (cl:setf continue (cl:cons '|compilation-unit| 716))
       (cl:setf pc 706)
     pc-706
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 707)
     pc-707
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-708
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 709)
     pc-709
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 710)
     pc-710
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 711)
     pc-711
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 712)
     pc-712
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-713
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 714)
     pc-714
       (cl:setf pc 716) (cl:go pc-716)
     pc-715
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 716)
     pc-716
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 717)
     pc-717
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 718)
     pc-718
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 719)
     pc-719
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 720)
     pc-720
       (cl:when flag (cl:setf pc 735) (cl:go pc-735))
     pc-721
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 722)
     pc-722
       (cl:when flag (cl:setf pc 728) (cl:go pc-728))
     pc-723
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 724)
     pc-724
       (cl:when flag (cl:setf pc 733) (cl:go pc-733))
     pc-725
       (cl:setf continue (cl:cons '|compilation-unit| 851))
       (cl:setf pc 726)
     pc-726
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 727)
     pc-727
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-728
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 729)
     pc-729
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 730)
     pc-730
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 731)
     pc-731
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 732)
     pc-732
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-733
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 734)
     pc-734
       (cl:setf pc 851) (cl:go pc-851)
     pc-735
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 736)
     pc-736
       (cl:setf pc 851) (cl:go pc-851)
     pc-737
       (cl:push env stack)
       (cl:setf pc 738)
     pc-738
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-char| env))
       (cl:setf pc 739)
     pc-739
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 1 env))
       (cl:setf pc 740)
     pc-740
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 741)
     pc-741
       (cl:setf val #\Newline)
       (cl:setf pc 742)
     pc-742
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 743)
     pc-743
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 744)
     pc-744
       (cl:when flag (cl:setf pc 759) (cl:go pc-759))
     pc-745
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 746)
     pc-746
       (cl:when flag (cl:setf pc 752) (cl:go pc-752))
     pc-747
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 748)
     pc-748
       (cl:when flag (cl:setf pc 757) (cl:go pc-757))
     pc-749
       (cl:setf continue (cl:cons '|compilation-unit| 760))
       (cl:setf pc 750)
     pc-750
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 751)
     pc-751
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-752
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 753)
     pc-753
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 754)
     pc-754
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 755)
     pc-755
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 756)
     pc-756
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-757
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 758)
     pc-758
       (cl:setf pc 760) (cl:go pc-760)
     pc-759
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 760)
     pc-760
       (cl:setf env (cl:pop stack))
       (cl:setf pc 761)
     pc-761
       (cl:push env stack)
       (cl:setf pc 762)
     pc-762
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-char| env))
       (cl:setf pc 763)
     pc-763
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 1 env))
       (cl:setf pc 764)
     pc-764
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 765)
     pc-765
       (cl:setf val #\Space)
       (cl:setf pc 766)
     pc-766
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 767)
     pc-767
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 768)
     pc-768
       (cl:when flag (cl:setf pc 783) (cl:go pc-783))
     pc-769
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 770)
     pc-770
       (cl:when flag (cl:setf pc 776) (cl:go pc-776))
     pc-771
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 772)
     pc-772
       (cl:when flag (cl:setf pc 781) (cl:go pc-781))
     pc-773
       (cl:setf continue (cl:cons '|compilation-unit| 784))
       (cl:setf pc 774)
     pc-774
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 775)
     pc-775
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-776
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 777)
     pc-777
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 778)
     pc-778
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 779)
     pc-779
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 780)
     pc-780
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-781
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 782)
     pc-782
       (cl:setf pc 784) (cl:go pc-784)
     pc-783
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 784)
     pc-784
       (cl:setf env (cl:pop stack))
       (cl:setf pc 785)
     pc-785
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-string-to-port| env))
       (cl:setf pc 786)
     pc-786
       (cl:push proc stack)
       (cl:setf pc 787)
     pc-787
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 1 env))
       (cl:setf pc 788)
     pc-788
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 789)
     pc-789
       (cl:push argl stack)
       (cl:setf pc 790)
     pc-790
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-to-string-flat| env))
       (cl:setf pc 791)
     pc-791
       (cl:push proc stack)
       (cl:setf pc 792)
     pc-792
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 793)
     pc-793
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 794)
     pc-794
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 795)
     pc-795
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 796)
     pc-796
       (cl:when flag (cl:setf pc 811) (cl:go pc-811))
     pc-797
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 798)
     pc-798
       (cl:when flag (cl:setf pc 804) (cl:go pc-804))
     pc-799
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 800)
     pc-800
       (cl:when flag (cl:setf pc 809) (cl:go pc-809))
     pc-801
       (cl:setf continue (cl:cons '|compilation-unit| 812))
       (cl:setf pc 802)
     pc-802
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 803)
     pc-803
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-804
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 805)
     pc-805
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 806)
     pc-806
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 807)
     pc-807
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 808)
     pc-808
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-809
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 810)
     pc-810
       (cl:setf pc 812) (cl:go pc-812)
     pc-811
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 812)
     pc-812
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 813)
     pc-813
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 814)
     pc-814
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 815)
     pc-815
       (cl:when flag (cl:setf pc 830) (cl:go pc-830))
     pc-816
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 817)
     pc-817
       (cl:when flag (cl:setf pc 823) (cl:go pc-823))
     pc-818
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 819)
     pc-819
       (cl:when flag (cl:setf pc 828) (cl:go pc-828))
     pc-820
       (cl:setf continue (cl:cons '|compilation-unit| 831))
       (cl:setf pc 821)
     pc-821
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 822)
     pc-822
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-823
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 824)
     pc-824
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 825)
     pc-825
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 826)
     pc-826
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 827)
     pc-827
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-828
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 829)
     pc-829
       (cl:setf pc 831) (cl:go pc-831)
     pc-830
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 831)
     pc-831
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 832)
     pc-832
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 833)
     pc-833
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 834)
     pc-834
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 835)
     pc-835
       (cl:when flag (cl:setf pc 850) (cl:go pc-850))
     pc-836
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 837)
     pc-837
       (cl:when flag (cl:setf pc 843) (cl:go pc-843))
     pc-838
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 839)
     pc-839
       (cl:when flag (cl:setf pc 848) (cl:go pc-848))
     pc-840
       (cl:setf continue (cl:cons '|compilation-unit| 851))
       (cl:setf pc 841)
     pc-841
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 842)
     pc-842
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-843
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 844)
     pc-844
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 845)
     pc-845
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 846)
     pc-846
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 847)
     pc-847
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-848
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 849)
     pc-849
       (cl:setf pc 851) (cl:go pc-851)
     pc-850
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 851)
     pc-851
       (cl:setf env (cl:pop stack))
       (cl:setf pc 852)
     pc-852
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 853)
     pc-853
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 854)
     pc-854
       (cl:push continue stack)
       (cl:setf pc 855)
     pc-855
       (cl:push proc stack)
       (cl:setf pc 856)
     pc-856
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 857)
     pc-857
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 858)
     pc-858
       (cl:push argl stack)
       (cl:setf pc 859)
     pc-859
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 860)
     pc-860
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 861)
     pc-861
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 862)
     pc-862
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 863)
     pc-863
       (cl:when flag (cl:setf pc 878) (cl:go pc-878))
     pc-864
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 865)
     pc-865
       (cl:when flag (cl:setf pc 871) (cl:go pc-871))
     pc-866
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 867)
     pc-867
       (cl:when flag (cl:setf pc 876) (cl:go pc-876))
     pc-868
       (cl:setf continue (cl:cons '|compilation-unit| 879))
       (cl:setf pc 869)
     pc-869
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 870)
     pc-870
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-871
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 872)
     pc-872
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 873)
     pc-873
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 874)
     pc-874
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 875)
     pc-875
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-876
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 877)
     pc-877
       (cl:setf pc 879) (cl:go pc-879)
     pc-878
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 879)
     pc-879
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 880)
     pc-880
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 881)
     pc-881
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 882)
     pc-882
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 883)
     pc-883
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 884)
     pc-884
       (cl:when flag (cl:setf pc 898) (cl:go pc-898))
     pc-885
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 886)
     pc-886
       (cl:when flag (cl:setf pc 891) (cl:go pc-891))
     pc-887
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 888)
     pc-888
       (cl:when flag (cl:setf pc 896) (cl:go pc-896))
     pc-889
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 890)
     pc-890
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-891
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 892)
     pc-892
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 893)
     pc-893
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 894)
     pc-894
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 895)
     pc-895
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-896
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 897)
     pc-897
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-898
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 899)
     pc-899
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-900
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 901)
     pc-901
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-902
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 903)
     pc-903
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 904)
     pc-904
       (cl:when flag (cl:setf pc 918) (cl:go pc-918))
     pc-905
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 906)
     pc-906
       (cl:when flag (cl:setf pc 911) (cl:go pc-911))
     pc-907
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 908)
     pc-908
       (cl:when flag (cl:setf pc 916) (cl:go pc-916))
     pc-909
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 910)
     pc-910
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-911
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 912)
     pc-912
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 913)
     pc-913
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 914)
     pc-914
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 915)
     pc-915
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-916
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 917)
     pc-917
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-918
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 919)
     pc-919
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-920
       (cl:setf val cl:nil)
       (cl:setf pc 921)
     pc-921
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 922)
     pc-922
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 923)
     pc-923
       (cl:when flag (cl:setf pc 940) (cl:go pc-940))
     pc-924
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 925)
     pc-925
       (cl:when flag (cl:setf pc 933) (cl:go pc-933))
     pc-926
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 927)
     pc-927
       (cl:when flag (cl:setf pc 938) (cl:go pc-938))
     pc-928
       (cl:setf continue (cl:cons '|compilation-unit| 931))
       (cl:setf pc 929)
     pc-929
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 930)
     pc-930
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-931
       (cl:setf proc val)
       (cl:setf pc 932)
     pc-932
       (cl:setf pc 941) (cl:go pc-941)
     pc-933
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 934)
     pc-934
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 935)
     pc-935
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 936)
     pc-936
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 937)
     pc-937
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-938
       (cl:setf proc (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 939)
     pc-939
       (cl:setf pc 941) (cl:go pc-941)
     pc-940
       (cl:setf proc (cl:funcall (get-operation '|apply-primitive-procedure|) proc argl))
       (cl:setf pc 941)
     pc-941
       (cl:setf env (cl:pop stack))
       (cl:setf pc 942)
     pc-942
       (cl:setf val t)
       (cl:setf pc 943)
     pc-943
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 944)
     pc-944
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 945)
     pc-945
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 946)
     pc-946
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 947)
     pc-947
       (cl:when flag (cl:setf pc 962) (cl:go pc-962))
     pc-948
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 949)
     pc-949
       (cl:when flag (cl:setf pc 955) (cl:go pc-955))
     pc-950
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 951)
     pc-951
       (cl:when flag (cl:setf pc 960) (cl:go pc-960))
     pc-952
       (cl:setf continue (cl:cons '|compilation-unit| 963))
       (cl:setf pc 953)
     pc-953
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 954)
     pc-954
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-955
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 956)
     pc-956
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 957)
     pc-957
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 958)
     pc-958
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 959)
     pc-959
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-960
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 961)
     pc-961
       (cl:setf pc 963) (cl:go pc-963)
     pc-962
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 963)
     pc-963
       (cl:setf env (cl:pop stack))
       (cl:setf pc 964)
     pc-964
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 965)
     pc-965
       (cl:push continue stack)
       (cl:setf pc 966)
     pc-966
       (cl:push env stack)
       (cl:setf pc 967)
     pc-967
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-char| env))
       (cl:setf pc 968)
     pc-968
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 969)
     pc-969
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 970)
     pc-970
       (cl:setf val #\))
       (cl:setf pc 971)
     pc-971
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 972)
     pc-972
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 973)
     pc-973
       (cl:when flag (cl:setf pc 988) (cl:go pc-988))
     pc-974
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 975)
     pc-975
       (cl:when flag (cl:setf pc 981) (cl:go pc-981))
     pc-976
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 977)
     pc-977
       (cl:when flag (cl:setf pc 986) (cl:go pc-986))
     pc-978
       (cl:setf continue (cl:cons '|compilation-unit| 989))
       (cl:setf pc 979)
     pc-979
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 980)
     pc-980
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-981
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 982)
     pc-982
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 983)
     pc-983
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 984)
     pc-984
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 985)
     pc-985
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-986
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 987)
     pc-987
       (cl:setf pc 989) (cl:go pc-989)
     pc-988
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 989)
     pc-989
       (cl:setf env (cl:pop stack))
       (cl:setf pc 990)
     pc-990
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 991)
     pc-991
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-char| env))
       (cl:setf pc 992)
     pc-992
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 993)
     pc-993
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 994)
     pc-994
       (cl:setf val #\Newline)
       (cl:setf pc 995)
     pc-995
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 996)
     pc-996
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 997)
     pc-997
       (cl:when flag (cl:setf pc 1011) (cl:go pc-1011))
     pc-998
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 999)
     pc-999
       (cl:when flag (cl:setf pc 1004) (cl:go pc-1004))
     pc-1000
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1001)
     pc-1001
       (cl:when flag (cl:setf pc 1009) (cl:go pc-1009))
     pc-1002
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1003)
     pc-1003
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1004
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1005)
     pc-1005
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1006)
     pc-1006
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1007)
     pc-1007
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1008)
     pc-1008
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1009
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1010)
     pc-1010
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1011
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1012)
     pc-1012
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1013
       (cl:funcall (get-operation '|define-variable!|) '|write-flat-instructions| val env)
       (cl:setf pc 1014)
     pc-1014
       (cl:setf val val)
       (cl:setf pc 1015)
     pc-1015
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 1016)
     pc-1016
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 1018 env))
       (cl:setf pc 1017)
     pc-1017
       (cl:setf pc 1353) (cl:go pc-1353)
     pc-1018
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1019)
     pc-1019
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|units|) argl env 0))
       (cl:setf pc 1020)
     pc-1020
       (cl:setf val "Merge compiled units into a single flat instruction list with env-resets between units.")
       (cl:setf pc 1021)
     pc-1021
       (cl:push continue stack)
       (cl:setf pc 1022)
     pc-1022
       (cl:push env stack)
       (cl:setf pc 1023)
     pc-1023
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|null?| env))
       (cl:setf pc 1024)
     pc-1024
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1025)
     pc-1025
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1026)
     pc-1026
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1027)
     pc-1027
       (cl:when flag (cl:setf pc 1042) (cl:go pc-1042))
     pc-1028
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1029)
     pc-1029
       (cl:when flag (cl:setf pc 1035) (cl:go pc-1035))
     pc-1030
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1031)
     pc-1031
       (cl:when flag (cl:setf pc 1040) (cl:go pc-1040))
     pc-1032
       (cl:setf continue (cl:cons '|compilation-unit| 1043))
       (cl:setf pc 1033)
     pc-1033
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1034)
     pc-1034
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1035
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1036)
     pc-1036
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1037)
     pc-1037
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1038)
     pc-1038
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1039)
     pc-1039
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1040
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1041)
     pc-1041
       (cl:setf pc 1043) (cl:go pc-1043)
     pc-1042
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1043)
     pc-1043
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1044)
     pc-1044
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1045)
     pc-1045
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 1046)
     pc-1046
       (cl:when flag (cl:setf pc 1049) (cl:go pc-1049))
     pc-1047
       (cl:setf val cl:nil)
       (cl:setf pc 1048)
     pc-1048
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1049
       (cl:push continue stack)
       (cl:setf pc 1050)
     pc-1050
       (cl:push env stack)
       (cl:setf pc 1051)
     pc-1051
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 1053 env))
       (cl:setf pc 1052)
     pc-1052
       (cl:setf pc 1311) (cl:go pc-1311)
     pc-1053
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1054)
     pc-1054
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|loop|) argl env 0))
       (cl:setf pc 1055)
     pc-1055
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 1057 env))
       (cl:setf pc 1056)
     pc-1056
       (cl:setf pc 1064) (cl:go pc-1064)
     pc-1057
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1058)
     pc-1058
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|g180|) argl env 0))
       (cl:setf pc 1059)
     pc-1059
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1060)
     pc-1060
       (cl:funcall (get-operation '|lexical-set!|) 1 0 val env)
       (cl:setf pc 1061)
     pc-1061
       (cl:setf val val)
       (cl:setf pc 1062)
     pc-1062
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 1063)
     pc-1063
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1064
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 1066 env))
       (cl:setf pc 1065)
     pc-1065
       (cl:setf pc 1293) (cl:go pc-1293)
     pc-1066
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1067)
     pc-1067
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|units|) argl env 0))
       (cl:setf pc 1068)
     pc-1068
       (cl:push continue stack)
       (cl:setf pc 1069)
     pc-1069
       (cl:push env stack)
       (cl:setf pc 1070)
     pc-1070
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|null?| env))
       (cl:setf pc 1071)
     pc-1071
       (cl:push proc stack)
       (cl:setf pc 1072)
     pc-1072
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 1073)
     pc-1073
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1074)
     pc-1074
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1075)
     pc-1075
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1076)
     pc-1076
       (cl:when flag (cl:setf pc 1091) (cl:go pc-1091))
     pc-1077
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1078)
     pc-1078
       (cl:when flag (cl:setf pc 1084) (cl:go pc-1084))
     pc-1079
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1080)
     pc-1080
       (cl:when flag (cl:setf pc 1089) (cl:go pc-1089))
     pc-1081
       (cl:setf continue (cl:cons '|compilation-unit| 1092))
       (cl:setf pc 1082)
     pc-1082
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1083)
     pc-1083
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1084
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1085)
     pc-1085
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1086)
     pc-1086
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1087)
     pc-1087
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1088)
     pc-1088
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1089
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1090)
     pc-1090
       (cl:setf pc 1092) (cl:go pc-1092)
     pc-1091
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1092)
     pc-1092
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1093)
     pc-1093
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1094)
     pc-1094
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1095)
     pc-1095
       (cl:when flag (cl:setf pc 1110) (cl:go pc-1110))
     pc-1096
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1097)
     pc-1097
       (cl:when flag (cl:setf pc 1103) (cl:go pc-1103))
     pc-1098
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1099)
     pc-1099
       (cl:when flag (cl:setf pc 1108) (cl:go pc-1108))
     pc-1100
       (cl:setf continue (cl:cons '|compilation-unit| 1111))
       (cl:setf pc 1101)
     pc-1101
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1102)
     pc-1102
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1103
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1104)
     pc-1104
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1105)
     pc-1105
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1106)
     pc-1106
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1107)
     pc-1107
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1108
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1109)
     pc-1109
       (cl:setf pc 1111) (cl:go pc-1111)
     pc-1110
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1111)
     pc-1111
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1112)
     pc-1112
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1113)
     pc-1113
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 1114)
     pc-1114
       (cl:when flag (cl:setf pc 1158) (cl:go pc-1158))
     pc-1115
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|compiled-unit-instructions| env))
       (cl:setf pc 1116)
     pc-1116
       (cl:push continue stack)
       (cl:setf pc 1117)
     pc-1117
       (cl:push proc stack)
       (cl:setf pc 1118)
     pc-1118
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 1119)
     pc-1119
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1120)
     pc-1120
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1121)
     pc-1121
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1122)
     pc-1122
       (cl:when flag (cl:setf pc 1137) (cl:go pc-1137))
     pc-1123
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1124)
     pc-1124
       (cl:when flag (cl:setf pc 1130) (cl:go pc-1130))
     pc-1125
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1126)
     pc-1126
       (cl:when flag (cl:setf pc 1135) (cl:go pc-1135))
     pc-1127
       (cl:setf continue (cl:cons '|compilation-unit| 1138))
       (cl:setf pc 1128)
     pc-1128
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1129)
     pc-1129
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1130
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1131)
     pc-1131
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1132)
     pc-1132
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1133)
     pc-1133
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1134)
     pc-1134
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1135
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1136)
     pc-1136
       (cl:setf pc 1138) (cl:go pc-1138)
     pc-1137
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1138)
     pc-1138
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1139)
     pc-1139
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1140)
     pc-1140
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1141)
     pc-1141
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1142)
     pc-1142
       (cl:when flag (cl:setf pc 1156) (cl:go pc-1156))
     pc-1143
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1144)
     pc-1144
       (cl:when flag (cl:setf pc 1149) (cl:go pc-1149))
     pc-1145
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1146)
     pc-1146
       (cl:when flag (cl:setf pc 1154) (cl:go pc-1154))
     pc-1147
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1148)
     pc-1148
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1149
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1150)
     pc-1150
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1151)
     pc-1151
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1152)
     pc-1152
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1153)
     pc-1153
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1154
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1155)
     pc-1155
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1156
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1157)
     pc-1157
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1158
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|append| env))
       (cl:setf pc 1159)
     pc-1159
       (cl:push continue stack)
       (cl:setf pc 1160)
     pc-1160
       (cl:push proc stack)
       (cl:setf pc 1161)
     pc-1161
       (cl:push env stack)
       (cl:setf pc 1162)
     pc-1162
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 1163)
     pc-1163
       (cl:push proc stack)
       (cl:setf pc 1164)
     pc-1164
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 1165)
     pc-1165
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1166)
     pc-1166
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1167)
     pc-1167
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1168)
     pc-1168
       (cl:when flag (cl:setf pc 1183) (cl:go pc-1183))
     pc-1169
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1170)
     pc-1170
       (cl:when flag (cl:setf pc 1176) (cl:go pc-1176))
     pc-1171
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1172)
     pc-1172
       (cl:when flag (cl:setf pc 1181) (cl:go pc-1181))
     pc-1173
       (cl:setf continue (cl:cons '|compilation-unit| 1184))
       (cl:setf pc 1174)
     pc-1174
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1175)
     pc-1175
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1176
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1177)
     pc-1177
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1178)
     pc-1178
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1179)
     pc-1179
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1180)
     pc-1180
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1181
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1182)
     pc-1182
       (cl:setf pc 1184) (cl:go pc-1184)
     pc-1183
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1184)
     pc-1184
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1185)
     pc-1185
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1186)
     pc-1186
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1187)
     pc-1187
       (cl:when flag (cl:setf pc 1202) (cl:go pc-1202))
     pc-1188
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1189)
     pc-1189
       (cl:when flag (cl:setf pc 1195) (cl:go pc-1195))
     pc-1190
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1191)
     pc-1191
       (cl:when flag (cl:setf pc 1200) (cl:go pc-1200))
     pc-1192
       (cl:setf continue (cl:cons '|compilation-unit| 1203))
       (cl:setf pc 1193)
     pc-1193
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1194)
     pc-1194
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1195
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1196)
     pc-1196
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1197)
     pc-1197
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1198)
     pc-1198
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1199)
     pc-1199
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1200
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1201)
     pc-1201
       (cl:setf pc 1203) (cl:go pc-1203)
     pc-1202
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1203)
     pc-1203
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1204)
     pc-1204
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1205)
     pc-1205
       (cl:push env stack)
       (cl:setf pc 1206)
     pc-1206
       (cl:push argl stack)
       (cl:setf pc 1207)
     pc-1207
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 1208)
     pc-1208
       (cl:setf val '(|assign| |env| (|op| |lookup-variable-value|) (|const| |*global-env*|) (|reg| |env|)))
       (cl:setf pc 1209)
     pc-1209
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1210)
     pc-1210
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1211)
     pc-1211
       (cl:when flag (cl:setf pc 1226) (cl:go pc-1226))
     pc-1212
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1213)
     pc-1213
       (cl:when flag (cl:setf pc 1219) (cl:go pc-1219))
     pc-1214
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1215)
     pc-1215
       (cl:when flag (cl:setf pc 1224) (cl:go pc-1224))
     pc-1216
       (cl:setf continue (cl:cons '|compilation-unit| 1227))
       (cl:setf pc 1217)
     pc-1217
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1218)
     pc-1218
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1219
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1220)
     pc-1220
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1221)
     pc-1221
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1222)
     pc-1222
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1223)
     pc-1223
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1224
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1225)
     pc-1225
       (cl:setf pc 1227) (cl:go pc-1227)
     pc-1226
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1227)
     pc-1227
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 1228)
     pc-1228
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1229)
     pc-1229
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1230)
     pc-1230
       (cl:push argl stack)
       (cl:setf pc 1231)
     pc-1231
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|compiled-unit-instructions| env))
       (cl:setf pc 1232)
     pc-1232
       (cl:push proc stack)
       (cl:setf pc 1233)
     pc-1233
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 1234)
     pc-1234
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1235)
     pc-1235
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1236)
     pc-1236
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1237)
     pc-1237
       (cl:when flag (cl:setf pc 1252) (cl:go pc-1252))
     pc-1238
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1239)
     pc-1239
       (cl:when flag (cl:setf pc 1245) (cl:go pc-1245))
     pc-1240
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1241)
     pc-1241
       (cl:when flag (cl:setf pc 1250) (cl:go pc-1250))
     pc-1242
       (cl:setf continue (cl:cons '|compilation-unit| 1253))
       (cl:setf pc 1243)
     pc-1243
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1244)
     pc-1244
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1245
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1246)
     pc-1246
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1247)
     pc-1247
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1248)
     pc-1248
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1249)
     pc-1249
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1250
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1251)
     pc-1251
       (cl:setf pc 1253) (cl:go pc-1253)
     pc-1252
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1253)
     pc-1253
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1254)
     pc-1254
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1255)
     pc-1255
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1256)
     pc-1256
       (cl:when flag (cl:setf pc 1271) (cl:go pc-1271))
     pc-1257
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1258)
     pc-1258
       (cl:when flag (cl:setf pc 1264) (cl:go pc-1264))
     pc-1259
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1260)
     pc-1260
       (cl:when flag (cl:setf pc 1269) (cl:go pc-1269))
     pc-1261
       (cl:setf continue (cl:cons '|compilation-unit| 1272))
       (cl:setf pc 1262)
     pc-1262
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1263)
     pc-1263
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1264
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1265)
     pc-1265
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1266)
     pc-1266
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1267)
     pc-1267
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1268)
     pc-1268
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1269
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1270)
     pc-1270
       (cl:setf pc 1272) (cl:go pc-1272)
     pc-1271
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1272)
     pc-1272
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 1273)
     pc-1273
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1274)
     pc-1274
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1275)
     pc-1275
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1276)
     pc-1276
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1277)
     pc-1277
       (cl:when flag (cl:setf pc 1291) (cl:go pc-1291))
     pc-1278
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1279)
     pc-1279
       (cl:when flag (cl:setf pc 1284) (cl:go pc-1284))
     pc-1280
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1281)
     pc-1281
       (cl:when flag (cl:setf pc 1289) (cl:go pc-1289))
     pc-1282
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1283)
     pc-1283
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1284
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1285)
     pc-1285
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1286)
     pc-1286
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1287)
     pc-1287
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1288)
     pc-1288
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1289
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1290)
     pc-1290
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1291
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1292)
     pc-1292
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1293
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1294)
     pc-1294
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1295)
     pc-1295
       (cl:when flag (cl:setf pc 1309) (cl:go pc-1309))
     pc-1296
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1297)
     pc-1297
       (cl:when flag (cl:setf pc 1302) (cl:go pc-1302))
     pc-1298
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1299)
     pc-1299
       (cl:when flag (cl:setf pc 1307) (cl:go pc-1307))
     pc-1300
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1301)
     pc-1301
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1302
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1303)
     pc-1303
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1304)
     pc-1304
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1305)
     pc-1305
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1306)
     pc-1306
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1307
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1308)
     pc-1308
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1309
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1310)
     pc-1310
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1311
       (cl:setf val cl:nil)
       (cl:setf pc 1312)
     pc-1312
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1313)
     pc-1313
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1314)
     pc-1314
       (cl:when flag (cl:setf pc 1331) (cl:go pc-1331))
     pc-1315
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1316)
     pc-1316
       (cl:when flag (cl:setf pc 1324) (cl:go pc-1324))
     pc-1317
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1318)
     pc-1318
       (cl:when flag (cl:setf pc 1329) (cl:go pc-1329))
     pc-1319
       (cl:setf continue (cl:cons '|compilation-unit| 1322))
       (cl:setf pc 1320)
     pc-1320
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1321)
     pc-1321
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1322
       (cl:setf proc val)
       (cl:setf pc 1323)
     pc-1323
       (cl:setf pc 1332) (cl:go pc-1332)
     pc-1324
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1325)
     pc-1325
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1326)
     pc-1326
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1327)
     pc-1327
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1328)
     pc-1328
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1329
       (cl:setf proc (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1330)
     pc-1330
       (cl:setf pc 1332) (cl:go pc-1332)
     pc-1331
       (cl:setf proc (cl:funcall (get-operation '|apply-primitive-procedure|) proc argl))
       (cl:setf pc 1332)
     pc-1332
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1333)
     pc-1333
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1334)
     pc-1334
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1335)
     pc-1335
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1336)
     pc-1336
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1337)
     pc-1337
       (cl:when flag (cl:setf pc 1351) (cl:go pc-1351))
     pc-1338
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1339)
     pc-1339
       (cl:when flag (cl:setf pc 1344) (cl:go pc-1344))
     pc-1340
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1341)
     pc-1341
       (cl:when flag (cl:setf pc 1349) (cl:go pc-1349))
     pc-1342
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1343)
     pc-1343
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1344
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1345)
     pc-1345
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1346)
     pc-1346
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1347)
     pc-1347
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1348)
     pc-1348
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1349
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1350)
     pc-1350
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1351
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1352)
     pc-1352
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1353
       (cl:funcall (get-operation '|define-variable!|) '|merge-instruction-lists| val env)
       (cl:setf pc 1354)
     pc-1354
       (cl:setf val val)
       (cl:setf pc 1355)
     pc-1355
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 1356)
     pc-1356
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 1358 env))
       (cl:setf pc 1357)
     pc-1357
       (cl:setf pc 1450) (cl:go pc-1450)
     pc-1358
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1359)
     pc-1359
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|unit| |port|) argl env 0))
       (cl:setf pc 1360)
     pc-1360
       (cl:setf val "Write a compiled unit to PORT with one instruction per line.
Labels are currently written as-is; deterministic gensym renaming is deferred.")
       (cl:setf pc 1361)
     pc-1361
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 1363 env))
       (cl:setf pc 1362)
     pc-1362
       (cl:setf pc 1387) (cl:go pc-1387)
     pc-1363
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1364)
     pc-1364
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|renamed|) argl env 0))
       (cl:setf pc 1365)
     pc-1365
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-flat-instructions| env))
       (cl:setf pc 1366)
     pc-1366
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 1367)
     pc-1367
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1368)
     pc-1368
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1369)
     pc-1369
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1370)
     pc-1370
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1371)
     pc-1371
       (cl:when flag (cl:setf pc 1385) (cl:go pc-1385))
     pc-1372
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1373)
     pc-1373
       (cl:when flag (cl:setf pc 1378) (cl:go pc-1378))
     pc-1374
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1375)
     pc-1375
       (cl:when flag (cl:setf pc 1383) (cl:go pc-1383))
     pc-1376
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1377)
     pc-1377
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1378
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1379)
     pc-1379
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1380)
     pc-1380
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1381)
     pc-1381
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1382)
     pc-1382
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1383
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1384)
     pc-1384
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1385
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1386)
     pc-1386
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1387
       (cl:push continue stack)
       (cl:setf pc 1388)
     pc-1388
       (cl:push proc stack)
       (cl:setf pc 1389)
     pc-1389
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|rename-labels| env))
       (cl:setf pc 1390)
     pc-1390
       (cl:push proc stack)
       (cl:setf pc 1391)
     pc-1391
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|compiled-unit-instructions| env))
       (cl:setf pc 1392)
     pc-1392
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1393)
     pc-1393
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1394)
     pc-1394
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1395)
     pc-1395
       (cl:when flag (cl:setf pc 1410) (cl:go pc-1410))
     pc-1396
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1397)
     pc-1397
       (cl:when flag (cl:setf pc 1403) (cl:go pc-1403))
     pc-1398
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1399)
     pc-1399
       (cl:when flag (cl:setf pc 1408) (cl:go pc-1408))
     pc-1400
       (cl:setf continue (cl:cons '|compilation-unit| 1411))
       (cl:setf pc 1401)
     pc-1401
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1402)
     pc-1402
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1403
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1404)
     pc-1404
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1405)
     pc-1405
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1406)
     pc-1406
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1407)
     pc-1407
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1408
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1409)
     pc-1409
       (cl:setf pc 1411) (cl:go pc-1411)
     pc-1410
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1411)
     pc-1411
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1412)
     pc-1412
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1413)
     pc-1413
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1414)
     pc-1414
       (cl:when flag (cl:setf pc 1429) (cl:go pc-1429))
     pc-1415
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1416)
     pc-1416
       (cl:when flag (cl:setf pc 1422) (cl:go pc-1422))
     pc-1417
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1418)
     pc-1418
       (cl:when flag (cl:setf pc 1427) (cl:go pc-1427))
     pc-1419
       (cl:setf continue (cl:cons '|compilation-unit| 1430))
       (cl:setf pc 1420)
     pc-1420
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1421)
     pc-1421
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1422
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1423)
     pc-1423
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1424)
     pc-1424
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1425)
     pc-1425
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1426)
     pc-1426
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1427
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1428)
     pc-1428
       (cl:setf pc 1430) (cl:go pc-1430)
     pc-1429
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1430)
     pc-1430
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1431)
     pc-1431
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1432)
     pc-1432
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1433)
     pc-1433
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1434)
     pc-1434
       (cl:when flag (cl:setf pc 1448) (cl:go pc-1448))
     pc-1435
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1436)
     pc-1436
       (cl:when flag (cl:setf pc 1441) (cl:go pc-1441))
     pc-1437
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1438)
     pc-1438
       (cl:when flag (cl:setf pc 1446) (cl:go pc-1446))
     pc-1439
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1440)
     pc-1440
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1441
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1442)
     pc-1442
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1443)
     pc-1443
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1444)
     pc-1444
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1445)
     pc-1445
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1446
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1447)
     pc-1447
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1448
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1449)
     pc-1449
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1450
       (cl:funcall (get-operation '|define-variable!|) '|write-compiled-unit| val env)
       (cl:setf pc 1451)
     pc-1451
       (cl:setf val val)
       (cl:setf pc 1452)
     pc-1452
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 1453)
     pc-1453
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 1455 env))
       (cl:setf pc 1454)
     pc-1454
       (cl:setf pc 1554) (cl:go pc-1554)
     pc-1455
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1456)
     pc-1456
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|port|) argl env 0))
       (cl:setf pc 1457)
     pc-1457
       (cl:setf val "Read a compiled unit from PORT. Returns eof on end of input.")
       (cl:setf pc 1458)
     pc-1458
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 1460 env))
       (cl:setf pc 1459)
     pc-1459
       (cl:setf pc 1512) (cl:go pc-1512)
     pc-1460
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1461)
     pc-1461
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|instructions|) argl env 0))
       (cl:setf pc 1462)
     pc-1462
       (cl:push continue stack)
       (cl:setf pc 1463)
     pc-1463
       (cl:push env stack)
       (cl:setf pc 1464)
     pc-1464
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eof?| env))
       (cl:setf pc 1465)
     pc-1465
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1466)
     pc-1466
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1467)
     pc-1467
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1468)
     pc-1468
       (cl:when flag (cl:setf pc 1483) (cl:go pc-1483))
     pc-1469
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1470)
     pc-1470
       (cl:when flag (cl:setf pc 1476) (cl:go pc-1476))
     pc-1471
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1472)
     pc-1472
       (cl:when flag (cl:setf pc 1481) (cl:go pc-1481))
     pc-1473
       (cl:setf continue (cl:cons '|compilation-unit| 1484))
       (cl:setf pc 1474)
     pc-1474
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1475)
     pc-1475
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1476
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1477)
     pc-1477
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1478)
     pc-1478
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1479)
     pc-1479
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1480)
     pc-1480
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1481
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1482)
     pc-1482
       (cl:setf pc 1484) (cl:go pc-1484)
     pc-1483
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1484)
     pc-1484
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1485)
     pc-1485
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1486)
     pc-1486
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 1487)
     pc-1487
       (cl:when flag (cl:setf pc 1490) (cl:go pc-1490))
     pc-1488
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1489)
     pc-1489
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1490
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 1491)
     pc-1491
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1492)
     pc-1492
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1493)
     pc-1493
       (cl:setf val '|compiled-unit|)
       (cl:setf pc 1494)
     pc-1494
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1495)
     pc-1495
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1496)
     pc-1496
       (cl:when flag (cl:setf pc 1510) (cl:go pc-1510))
     pc-1497
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1498)
     pc-1498
       (cl:when flag (cl:setf pc 1503) (cl:go pc-1503))
     pc-1499
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1500)
     pc-1500
       (cl:when flag (cl:setf pc 1508) (cl:go pc-1508))
     pc-1501
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1502)
     pc-1502
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1503
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1504)
     pc-1504
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1505)
     pc-1505
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1506)
     pc-1506
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1507)
     pc-1507
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1508
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1509)
     pc-1509
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1510
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1511)
     pc-1511
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1512
       (cl:push continue stack)
       (cl:setf pc 1513)
     pc-1513
       (cl:push proc stack)
       (cl:setf pc 1514)
     pc-1514
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|ece-scheme-read| env))
       (cl:setf pc 1515)
     pc-1515
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1516)
     pc-1516
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1517)
     pc-1517
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1518)
     pc-1518
       (cl:when flag (cl:setf pc 1533) (cl:go pc-1533))
     pc-1519
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1520)
     pc-1520
       (cl:when flag (cl:setf pc 1526) (cl:go pc-1526))
     pc-1521
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1522)
     pc-1522
       (cl:when flag (cl:setf pc 1531) (cl:go pc-1531))
     pc-1523
       (cl:setf continue (cl:cons '|compilation-unit| 1534))
       (cl:setf pc 1524)
     pc-1524
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1525)
     pc-1525
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1526
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1527)
     pc-1527
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1528)
     pc-1528
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1529)
     pc-1529
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1530)
     pc-1530
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1531
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1532)
     pc-1532
       (cl:setf pc 1534) (cl:go pc-1534)
     pc-1533
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1534)
     pc-1534
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1535)
     pc-1535
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1536)
     pc-1536
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1537)
     pc-1537
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1538)
     pc-1538
       (cl:when flag (cl:setf pc 1552) (cl:go pc-1552))
     pc-1539
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1540)
     pc-1540
       (cl:when flag (cl:setf pc 1545) (cl:go pc-1545))
     pc-1541
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1542)
     pc-1542
       (cl:when flag (cl:setf pc 1550) (cl:go pc-1550))
     pc-1543
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1544)
     pc-1544
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1545
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1546)
     pc-1546
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1547)
     pc-1547
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1548)
     pc-1548
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1549)
     pc-1549
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1550
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1551)
     pc-1551
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1552
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1553)
     pc-1553
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1554
       (cl:funcall (get-operation '|define-variable!|) '|read-compiled-unit| val env)
       (cl:setf pc 1555)
     pc-1555
       (cl:setf val val)
       (cl:setf pc 1556)
     pc-1556
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 1557)
     pc-1557
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 1559 env))
       (cl:setf pc 1558)
     pc-1558
       (cl:setf pc 2520) (cl:go pc-2520)
     pc-1559
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1560)
     pc-1560
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|instrs|) argl env 0))
       (cl:setf pc 1561)
     pc-1561
       (cl:setf val "Extract source-map entries from instruction list containing source-location markers.
Returns (stripped-instrs . source-map-entries) where entries are (pc line col) triples
sorted by PC. Source-location markers are removed from the instruction list.")
       (cl:setf pc 1562)
     pc-1562
       (cl:push continue stack)
       (cl:setf pc 1563)
     pc-1563
       (cl:push env stack)
       (cl:setf pc 1564)
     pc-1564
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 1566 env))
       (cl:setf pc 1565)
     pc-1565
       (cl:setf pc 2472) (cl:go pc-2472)
     pc-1566
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1567)
     pc-1567
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|loop|) argl env 0))
       (cl:setf pc 1568)
     pc-1568
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 1570 env))
       (cl:setf pc 1569)
     pc-1569
       (cl:setf pc 1577) (cl:go pc-1577)
     pc-1570
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1571)
     pc-1571
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|g181|) argl env 0))
       (cl:setf pc 1572)
     pc-1572
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1573)
     pc-1573
       (cl:funcall (get-operation '|lexical-set!|) 1 0 val env)
       (cl:setf pc 1574)
     pc-1574
       (cl:setf val val)
       (cl:setf pc 1575)
     pc-1575
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 1576)
     pc-1576
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1577
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 1579 env))
       (cl:setf pc 1578)
     pc-1578
       (cl:setf pc 2454) (cl:go pc-2454)
     pc-1579
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1580)
     pc-1580
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|items| |pc| |stripped| |entries|) argl env 0))
       (cl:setf pc 1581)
     pc-1581
       (cl:push continue stack)
       (cl:setf pc 1582)
     pc-1582
       (cl:push env stack)
       (cl:setf pc 1583)
     pc-1583
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|null?| env))
       (cl:setf pc 1584)
     pc-1584
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1585)
     pc-1585
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1586)
     pc-1586
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1587)
     pc-1587
       (cl:when flag (cl:setf pc 1602) (cl:go pc-1602))
     pc-1588
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1589)
     pc-1589
       (cl:when flag (cl:setf pc 1595) (cl:go pc-1595))
     pc-1590
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1591)
     pc-1591
       (cl:when flag (cl:setf pc 1600) (cl:go pc-1600))
     pc-1592
       (cl:setf continue (cl:cons '|compilation-unit| 1603))
       (cl:setf pc 1593)
     pc-1593
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1594)
     pc-1594
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1595
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1596)
     pc-1596
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1597)
     pc-1597
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1598)
     pc-1598
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1599)
     pc-1599
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1600
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1601)
     pc-1601
       (cl:setf pc 1603) (cl:go pc-1603)
     pc-1602
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1603)
     pc-1603
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1604)
     pc-1604
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1605)
     pc-1605
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 1606)
     pc-1606
       (cl:when flag (cl:setf pc 1675) (cl:go pc-1675))
     pc-1607
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 1608)
     pc-1608
       (cl:push continue stack)
       (cl:setf pc 1609)
     pc-1609
       (cl:push proc stack)
       (cl:setf pc 1610)
     pc-1610
       (cl:push env stack)
       (cl:setf pc 1611)
     pc-1611
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|reverse| env))
       (cl:setf pc 1612)
     pc-1612
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 3 env))
       (cl:setf pc 1613)
     pc-1613
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1614)
     pc-1614
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1615)
     pc-1615
       (cl:when flag (cl:setf pc 1630) (cl:go pc-1630))
     pc-1616
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1617)
     pc-1617
       (cl:when flag (cl:setf pc 1623) (cl:go pc-1623))
     pc-1618
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1619)
     pc-1619
       (cl:when flag (cl:setf pc 1628) (cl:go pc-1628))
     pc-1620
       (cl:setf continue (cl:cons '|compilation-unit| 1631))
       (cl:setf pc 1621)
     pc-1621
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1622)
     pc-1622
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1623
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1624)
     pc-1624
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1625)
     pc-1625
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1626)
     pc-1626
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1627)
     pc-1627
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1628
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1629)
     pc-1629
       (cl:setf pc 1631) (cl:go pc-1631)
     pc-1630
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1631)
     pc-1631
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1632)
     pc-1632
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1633)
     pc-1633
       (cl:push argl stack)
       (cl:setf pc 1634)
     pc-1634
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|reverse| env))
       (cl:setf pc 1635)
     pc-1635
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 2 env))
       (cl:setf pc 1636)
     pc-1636
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1637)
     pc-1637
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1638)
     pc-1638
       (cl:when flag (cl:setf pc 1653) (cl:go pc-1653))
     pc-1639
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1640)
     pc-1640
       (cl:when flag (cl:setf pc 1646) (cl:go pc-1646))
     pc-1641
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1642)
     pc-1642
       (cl:when flag (cl:setf pc 1651) (cl:go pc-1651))
     pc-1643
       (cl:setf continue (cl:cons '|compilation-unit| 1654))
       (cl:setf pc 1644)
     pc-1644
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1645)
     pc-1645
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1646
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1647)
     pc-1647
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1648)
     pc-1648
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1649)
     pc-1649
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1650)
     pc-1650
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1651
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1652)
     pc-1652
       (cl:setf pc 1654) (cl:go pc-1654)
     pc-1653
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1654)
     pc-1654
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 1655)
     pc-1655
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1656)
     pc-1656
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1657)
     pc-1657
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1658)
     pc-1658
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1659)
     pc-1659
       (cl:when flag (cl:setf pc 1673) (cl:go pc-1673))
     pc-1660
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1661)
     pc-1661
       (cl:when flag (cl:setf pc 1666) (cl:go pc-1666))
     pc-1662
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1663)
     pc-1663
       (cl:when flag (cl:setf pc 1671) (cl:go pc-1671))
     pc-1664
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1665)
     pc-1665
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1666
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1667)
     pc-1667
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1668)
     pc-1668
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1669)
     pc-1669
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1670)
     pc-1670
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1671
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1672)
     pc-1672
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1673
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1674)
     pc-1674
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1675
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 1677 env))
       (cl:setf pc 1676)
     pc-1676
       (cl:setf pc 2412) (cl:go pc-2412)
     pc-1677
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 1678)
     pc-1678
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|item|) argl env 0))
       (cl:setf pc 1679)
     pc-1679
       (cl:push continue stack)
       (cl:setf pc 1680)
     pc-1680
       (cl:push env stack)
       (cl:setf pc 1681)
     pc-1681
       (cl:push env stack)
       (cl:setf pc 1682)
     pc-1682
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 1683)
     pc-1683
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1684)
     pc-1684
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1685)
     pc-1685
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1686)
     pc-1686
       (cl:when flag (cl:setf pc 1701) (cl:go pc-1701))
     pc-1687
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1688)
     pc-1688
       (cl:when flag (cl:setf pc 1694) (cl:go pc-1694))
     pc-1689
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1690)
     pc-1690
       (cl:when flag (cl:setf pc 1699) (cl:go pc-1699))
     pc-1691
       (cl:setf continue (cl:cons '|compilation-unit| 1702))
       (cl:setf pc 1692)
     pc-1692
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1693)
     pc-1693
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1694
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1695)
     pc-1695
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1696)
     pc-1696
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1697)
     pc-1697
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1698)
     pc-1698
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1699
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1700)
     pc-1700
       (cl:setf pc 1702) (cl:go pc-1702)
     pc-1701
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1702)
     pc-1702
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1703)
     pc-1703
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 1704)
     pc-1704
       (cl:when flag (cl:setf pc 1751) (cl:go pc-1751))
     pc-1705
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 1706)
     pc-1706
       (cl:push proc stack)
       (cl:setf pc 1707)
     pc-1707
       (cl:setf val '|source-location|)
       (cl:setf pc 1708)
     pc-1708
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1709)
     pc-1709
       (cl:push argl stack)
       (cl:setf pc 1710)
     pc-1710
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 1711)
     pc-1711
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1712)
     pc-1712
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1713)
     pc-1713
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1714)
     pc-1714
       (cl:when flag (cl:setf pc 1729) (cl:go pc-1729))
     pc-1715
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1716)
     pc-1716
       (cl:when flag (cl:setf pc 1722) (cl:go pc-1722))
     pc-1717
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1718)
     pc-1718
       (cl:when flag (cl:setf pc 1727) (cl:go pc-1727))
     pc-1719
       (cl:setf continue (cl:cons '|compilation-unit| 1730))
       (cl:setf pc 1720)
     pc-1720
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1721)
     pc-1721
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1722
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1723)
     pc-1723
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1724)
     pc-1724
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1725)
     pc-1725
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1726)
     pc-1726
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1727
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1728)
     pc-1728
       (cl:setf pc 1730) (cl:go pc-1730)
     pc-1729
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1730)
     pc-1730
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 1731)
     pc-1731
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1732)
     pc-1732
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1733)
     pc-1733
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1734)
     pc-1734
       (cl:when flag (cl:setf pc 1749) (cl:go pc-1749))
     pc-1735
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1736)
     pc-1736
       (cl:when flag (cl:setf pc 1742) (cl:go pc-1742))
     pc-1737
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1738)
     pc-1738
       (cl:when flag (cl:setf pc 1747) (cl:go pc-1747))
     pc-1739
       (cl:setf continue (cl:cons '|compilation-unit| 1752))
       (cl:setf pc 1740)
     pc-1740
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1741)
     pc-1741
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1742
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1743)
     pc-1743
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1744)
     pc-1744
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1745)
     pc-1745
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1746)
     pc-1746
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1747
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1748)
     pc-1748
       (cl:setf pc 1752) (cl:go pc-1752)
     pc-1749
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1750)
     pc-1750
       (cl:setf pc 1752) (cl:go pc-1752)
     pc-1751
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 1752)
     pc-1752
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1753)
     pc-1753
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1754)
     pc-1754
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 1755)
     pc-1755
       (cl:when flag (cl:setf pc 1903) (cl:go pc-1903))
     pc-1756
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 1757)
     pc-1757
       (cl:push continue stack)
       (cl:setf pc 1758)
     pc-1758
       (cl:push proc stack)
       (cl:setf pc 1759)
     pc-1759
       (cl:push env stack)
       (cl:setf pc 1760)
     pc-1760
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 1761)
     pc-1761
       (cl:push proc stack)
       (cl:setf pc 1762)
     pc-1762
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 3 env))
       (cl:setf pc 1763)
     pc-1763
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1764)
     pc-1764
       (cl:push argl stack)
       (cl:setf pc 1765)
     pc-1765
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 1766)
     pc-1766
       (cl:push proc stack)
       (cl:setf pc 1767)
     pc-1767
       (cl:push env stack)
       (cl:setf pc 1768)
     pc-1768
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadddr| env))
       (cl:setf pc 1769)
     pc-1769
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1770)
     pc-1770
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1771)
     pc-1771
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1772)
     pc-1772
       (cl:when flag (cl:setf pc 1787) (cl:go pc-1787))
     pc-1773
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1774)
     pc-1774
       (cl:when flag (cl:setf pc 1780) (cl:go pc-1780))
     pc-1775
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1776)
     pc-1776
       (cl:when flag (cl:setf pc 1785) (cl:go pc-1785))
     pc-1777
       (cl:setf continue (cl:cons '|compilation-unit| 1788))
       (cl:setf pc 1778)
     pc-1778
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1779)
     pc-1779
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1780
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1781)
     pc-1781
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1782)
     pc-1782
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1783)
     pc-1783
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1784)
     pc-1784
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1785
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1786)
     pc-1786
       (cl:setf pc 1788) (cl:go pc-1788)
     pc-1787
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1788)
     pc-1788
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1789)
     pc-1789
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1790)
     pc-1790
       (cl:push env stack)
       (cl:setf pc 1791)
     pc-1791
       (cl:push argl stack)
       (cl:setf pc 1792)
     pc-1792
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|caddr| env))
       (cl:setf pc 1793)
     pc-1793
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1794)
     pc-1794
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1795)
     pc-1795
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1796)
     pc-1796
       (cl:when flag (cl:setf pc 1811) (cl:go pc-1811))
     pc-1797
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1798)
     pc-1798
       (cl:when flag (cl:setf pc 1804) (cl:go pc-1804))
     pc-1799
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1800)
     pc-1800
       (cl:when flag (cl:setf pc 1809) (cl:go pc-1809))
     pc-1801
       (cl:setf continue (cl:cons '|compilation-unit| 1812))
       (cl:setf pc 1802)
     pc-1802
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1803)
     pc-1803
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1804
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1805)
     pc-1805
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1806)
     pc-1806
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1807)
     pc-1807
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1808)
     pc-1808
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1809
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1810)
     pc-1810
       (cl:setf pc 1812) (cl:go pc-1812)
     pc-1811
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1812)
     pc-1812
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 1813)
     pc-1813
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1814)
     pc-1814
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1815)
     pc-1815
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 1816)
     pc-1816
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1817)
     pc-1817
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1818)
     pc-1818
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1819)
     pc-1819
       (cl:when flag (cl:setf pc 1834) (cl:go pc-1834))
     pc-1820
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1821)
     pc-1821
       (cl:when flag (cl:setf pc 1827) (cl:go pc-1827))
     pc-1822
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1823)
     pc-1823
       (cl:when flag (cl:setf pc 1832) (cl:go pc-1832))
     pc-1824
       (cl:setf continue (cl:cons '|compilation-unit| 1835))
       (cl:setf pc 1825)
     pc-1825
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1826)
     pc-1826
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1827
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1828)
     pc-1828
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1829)
     pc-1829
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1830)
     pc-1830
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1831)
     pc-1831
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1832
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1833)
     pc-1833
       (cl:setf pc 1835) (cl:go pc-1835)
     pc-1834
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1835)
     pc-1835
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 1836)
     pc-1836
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1837)
     pc-1837
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1838)
     pc-1838
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1839)
     pc-1839
       (cl:when flag (cl:setf pc 1854) (cl:go pc-1854))
     pc-1840
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1841)
     pc-1841
       (cl:when flag (cl:setf pc 1847) (cl:go pc-1847))
     pc-1842
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1843)
     pc-1843
       (cl:when flag (cl:setf pc 1852) (cl:go pc-1852))
     pc-1844
       (cl:setf continue (cl:cons '|compilation-unit| 1855))
       (cl:setf pc 1845)
     pc-1845
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1846)
     pc-1846
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1847
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1848)
     pc-1848
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1849)
     pc-1849
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1850)
     pc-1850
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1851)
     pc-1851
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1852
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1853)
     pc-1853
       (cl:setf pc 1855) (cl:go pc-1855)
     pc-1854
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1855)
     pc-1855
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1856)
     pc-1856
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1857)
     pc-1857
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 2 env))
       (cl:setf pc 1858)
     pc-1858
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1859)
     pc-1859
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 1860)
     pc-1860
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1861)
     pc-1861
       (cl:push argl stack)
       (cl:setf pc 1862)
     pc-1862
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 1863)
     pc-1863
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 1864)
     pc-1864
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1865)
     pc-1865
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1866)
     pc-1866
       (cl:when flag (cl:setf pc 1881) (cl:go pc-1881))
     pc-1867
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1868)
     pc-1868
       (cl:when flag (cl:setf pc 1874) (cl:go pc-1874))
     pc-1869
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1870)
     pc-1870
       (cl:when flag (cl:setf pc 1879) (cl:go pc-1879))
     pc-1871
       (cl:setf continue (cl:cons '|compilation-unit| 1882))
       (cl:setf pc 1872)
     pc-1872
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1873)
     pc-1873
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1874
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1875)
     pc-1875
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1876)
     pc-1876
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1877)
     pc-1877
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1878)
     pc-1878
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1879
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1880)
     pc-1880
       (cl:setf pc 1882) (cl:go pc-1882)
     pc-1881
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1882)
     pc-1882
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 1883)
     pc-1883
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1884)
     pc-1884
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1885)
     pc-1885
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1886)
     pc-1886
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1887)
     pc-1887
       (cl:when flag (cl:setf pc 1901) (cl:go pc-1901))
     pc-1888
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1889)
     pc-1889
       (cl:when flag (cl:setf pc 1894) (cl:go pc-1894))
     pc-1890
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1891)
     pc-1891
       (cl:when flag (cl:setf pc 1899) (cl:go pc-1899))
     pc-1892
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1893)
     pc-1893
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1894
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1895)
     pc-1895
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1896)
     pc-1896
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1897)
     pc-1897
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1898)
     pc-1898
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1899
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1900)
     pc-1900
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1901
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1902)
     pc-1902
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1903
       (cl:push continue stack)
       (cl:setf pc 1904)
     pc-1904
       (cl:push env stack)
       (cl:setf pc 1905)
     pc-1905
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|symbol?| env))
       (cl:setf pc 1906)
     pc-1906
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1907)
     pc-1907
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1908)
     pc-1908
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1909)
     pc-1909
       (cl:when flag (cl:setf pc 1924) (cl:go pc-1924))
     pc-1910
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1911)
     pc-1911
       (cl:when flag (cl:setf pc 1917) (cl:go pc-1917))
     pc-1912
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1913)
     pc-1913
       (cl:when flag (cl:setf pc 1922) (cl:go pc-1922))
     pc-1914
       (cl:setf continue (cl:cons '|compilation-unit| 1925))
       (cl:setf pc 1915)
     pc-1915
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1916)
     pc-1916
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1917
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1918)
     pc-1918
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1919)
     pc-1919
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1920)
     pc-1920
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1921)
     pc-1921
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1922
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1923)
     pc-1923
       (cl:setf pc 1925) (cl:go pc-1925)
     pc-1924
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1925)
     pc-1925
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1926)
     pc-1926
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1927)
     pc-1927
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 1928)
     pc-1928
       (cl:when flag (cl:setf pc 2005) (cl:go pc-2005))
     pc-1929
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 1930)
     pc-1930
       (cl:push continue stack)
       (cl:setf pc 1931)
     pc-1931
       (cl:push proc stack)
       (cl:setf pc 1932)
     pc-1932
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 3 env))
       (cl:setf pc 1933)
     pc-1933
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1934)
     pc-1934
       (cl:push env stack)
       (cl:setf pc 1935)
     pc-1935
       (cl:push argl stack)
       (cl:setf pc 1936)
     pc-1936
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 1937)
     pc-1937
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 2 env))
       (cl:setf pc 1938)
     pc-1938
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1939)
     pc-1939
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 1940)
     pc-1940
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1941)
     pc-1941
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1942)
     pc-1942
       (cl:when flag (cl:setf pc 1957) (cl:go pc-1957))
     pc-1943
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1944)
     pc-1944
       (cl:when flag (cl:setf pc 1950) (cl:go pc-1950))
     pc-1945
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1946)
     pc-1946
       (cl:when flag (cl:setf pc 1955) (cl:go pc-1955))
     pc-1947
       (cl:setf continue (cl:cons '|compilation-unit| 1958))
       (cl:setf pc 1948)
     pc-1948
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1949)
     pc-1949
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1950
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1951)
     pc-1951
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1952)
     pc-1952
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1953)
     pc-1953
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1954)
     pc-1954
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1955
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1956)
     pc-1956
       (cl:setf pc 1958) (cl:go pc-1958)
     pc-1957
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1958)
     pc-1958
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 1959)
     pc-1959
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1960)
     pc-1960
       (cl:setf env (cl:pop stack))
       (cl:setf pc 1961)
     pc-1961
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 1962)
     pc-1962
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1963)
     pc-1963
       (cl:push argl stack)
       (cl:setf pc 1964)
     pc-1964
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 1965)
     pc-1965
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 1966)
     pc-1966
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 1967)
     pc-1967
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1968)
     pc-1968
       (cl:when flag (cl:setf pc 1983) (cl:go pc-1983))
     pc-1969
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1970)
     pc-1970
       (cl:when flag (cl:setf pc 1976) (cl:go pc-1976))
     pc-1971
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1972)
     pc-1972
       (cl:when flag (cl:setf pc 1981) (cl:go pc-1981))
     pc-1973
       (cl:setf continue (cl:cons '|compilation-unit| 1984))
       (cl:setf pc 1974)
     pc-1974
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1975)
     pc-1975
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1976
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1977)
     pc-1977
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1978)
     pc-1978
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1979)
     pc-1979
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 1980)
     pc-1980
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1981
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 1982)
     pc-1982
       (cl:setf pc 1984) (cl:go pc-1984)
     pc-1983
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 1984)
     pc-1984
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 1985)
     pc-1985
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 1986)
     pc-1986
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 1987)
     pc-1987
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 1988)
     pc-1988
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 1989)
     pc-1989
       (cl:when flag (cl:setf pc 2003) (cl:go pc-2003))
     pc-1990
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 1991)
     pc-1991
       (cl:when flag (cl:setf pc 1996) (cl:go pc-1996))
     pc-1992
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 1993)
     pc-1993
       (cl:when flag (cl:setf pc 2001) (cl:go pc-2001))
     pc-1994
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 1995)
     pc-1995
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-1996
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 1997)
     pc-1997
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 1998)
     pc-1998
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 1999)
     pc-1999
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2000)
     pc-2000
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2001
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2002)
     pc-2002
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2003
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2004)
     pc-2004
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2005
       (cl:push continue stack)
       (cl:setf pc 2006)
     pc-2006
       (cl:push env stack)
       (cl:setf pc 2007)
     pc-2007
       (cl:push env stack)
       (cl:setf pc 2008)
     pc-2008
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 2009)
     pc-2009
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2010)
     pc-2010
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2011)
     pc-2011
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2012)
     pc-2012
       (cl:when flag (cl:setf pc 2027) (cl:go pc-2027))
     pc-2013
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2014)
     pc-2014
       (cl:when flag (cl:setf pc 2020) (cl:go pc-2020))
     pc-2015
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2016)
     pc-2016
       (cl:when flag (cl:setf pc 2025) (cl:go pc-2025))
     pc-2017
       (cl:setf continue (cl:cons '|compilation-unit| 2028))
       (cl:setf pc 2018)
     pc-2018
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2019)
     pc-2019
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2020
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2021)
     pc-2021
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2022)
     pc-2022
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2023)
     pc-2023
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2024)
     pc-2024
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2025
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2026)
     pc-2026
       (cl:setf pc 2028) (cl:go pc-2028)
     pc-2027
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2028)
     pc-2028
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2029)
     pc-2029
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 2030)
     pc-2030
       (cl:when flag (cl:setf pc 2077) (cl:go pc-2077))
     pc-2031
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 2032)
     pc-2032
       (cl:push proc stack)
       (cl:setf pc 2033)
     pc-2033
       (cl:setf val '|procedure-name|)
       (cl:setf pc 2034)
     pc-2034
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2035)
     pc-2035
       (cl:push argl stack)
       (cl:setf pc 2036)
     pc-2036
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 2037)
     pc-2037
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2038)
     pc-2038
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2039)
     pc-2039
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2040)
     pc-2040
       (cl:when flag (cl:setf pc 2055) (cl:go pc-2055))
     pc-2041
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2042)
     pc-2042
       (cl:when flag (cl:setf pc 2048) (cl:go pc-2048))
     pc-2043
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2044)
     pc-2044
       (cl:when flag (cl:setf pc 2053) (cl:go pc-2053))
     pc-2045
       (cl:setf continue (cl:cons '|compilation-unit| 2056))
       (cl:setf pc 2046)
     pc-2046
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2047)
     pc-2047
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2048
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2049)
     pc-2049
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2050)
     pc-2050
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2051)
     pc-2051
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2052)
     pc-2052
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2053
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2054)
     pc-2054
       (cl:setf pc 2056) (cl:go pc-2056)
     pc-2055
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2056)
     pc-2056
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2057)
     pc-2057
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2058)
     pc-2058
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2059)
     pc-2059
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2060)
     pc-2060
       (cl:when flag (cl:setf pc 2075) (cl:go pc-2075))
     pc-2061
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2062)
     pc-2062
       (cl:when flag (cl:setf pc 2068) (cl:go pc-2068))
     pc-2063
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2064)
     pc-2064
       (cl:when flag (cl:setf pc 2073) (cl:go pc-2073))
     pc-2065
       (cl:setf continue (cl:cons '|compilation-unit| 2078))
       (cl:setf pc 2066)
     pc-2066
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2067)
     pc-2067
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2068
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2069)
     pc-2069
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2070)
     pc-2070
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2071)
     pc-2071
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2072)
     pc-2072
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2073
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2074)
     pc-2074
       (cl:setf pc 2078) (cl:go pc-2078)
     pc-2075
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2076)
     pc-2076
       (cl:setf pc 2078) (cl:go pc-2078)
     pc-2077
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 2078)
     pc-2078
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2079)
     pc-2079
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2080)
     pc-2080
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 2081)
     pc-2081
       (cl:when flag (cl:setf pc 2158) (cl:go pc-2158))
     pc-2082
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 2083)
     pc-2083
       (cl:push continue stack)
       (cl:setf pc 2084)
     pc-2084
       (cl:push proc stack)
       (cl:setf pc 2085)
     pc-2085
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 3 env))
       (cl:setf pc 2086)
     pc-2086
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2087)
     pc-2087
       (cl:push env stack)
       (cl:setf pc 2088)
     pc-2088
       (cl:push argl stack)
       (cl:setf pc 2089)
     pc-2089
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 2090)
     pc-2090
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 2 env))
       (cl:setf pc 2091)
     pc-2091
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2092)
     pc-2092
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2093)
     pc-2093
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2094)
     pc-2094
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2095)
     pc-2095
       (cl:when flag (cl:setf pc 2110) (cl:go pc-2110))
     pc-2096
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2097)
     pc-2097
       (cl:when flag (cl:setf pc 2103) (cl:go pc-2103))
     pc-2098
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2099)
     pc-2099
       (cl:when flag (cl:setf pc 2108) (cl:go pc-2108))
     pc-2100
       (cl:setf continue (cl:cons '|compilation-unit| 2111))
       (cl:setf pc 2101)
     pc-2101
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2102)
     pc-2102
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2103
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2104)
     pc-2104
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2105)
     pc-2105
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2106)
     pc-2106
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2107)
     pc-2107
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2108
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2109)
     pc-2109
       (cl:setf pc 2111) (cl:go pc-2111)
     pc-2110
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2111)
     pc-2111
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2112)
     pc-2112
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2113)
     pc-2113
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2114)
     pc-2114
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 2115)
     pc-2115
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2116)
     pc-2116
       (cl:push argl stack)
       (cl:setf pc 2117)
     pc-2117
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 2118)
     pc-2118
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 2119)
     pc-2119
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2120)
     pc-2120
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2121)
     pc-2121
       (cl:when flag (cl:setf pc 2136) (cl:go pc-2136))
     pc-2122
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2123)
     pc-2123
       (cl:when flag (cl:setf pc 2129) (cl:go pc-2129))
     pc-2124
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2125)
     pc-2125
       (cl:when flag (cl:setf pc 2134) (cl:go pc-2134))
     pc-2126
       (cl:setf continue (cl:cons '|compilation-unit| 2137))
       (cl:setf pc 2127)
     pc-2127
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2128)
     pc-2128
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2129
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2130)
     pc-2130
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2131)
     pc-2131
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2132)
     pc-2132
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2133)
     pc-2133
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2134
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2135)
     pc-2135
       (cl:setf pc 2137) (cl:go pc-2137)
     pc-2136
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2137)
     pc-2137
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2138)
     pc-2138
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2139)
     pc-2139
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2140)
     pc-2140
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2141)
     pc-2141
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2142)
     pc-2142
       (cl:when flag (cl:setf pc 2156) (cl:go pc-2156))
     pc-2143
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2144)
     pc-2144
       (cl:when flag (cl:setf pc 2149) (cl:go pc-2149))
     pc-2145
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2146)
     pc-2146
       (cl:when flag (cl:setf pc 2154) (cl:go pc-2154))
     pc-2147
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2148)
     pc-2148
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2149
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2150)
     pc-2150
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2151)
     pc-2151
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2152)
     pc-2152
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2153)
     pc-2153
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2154
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2155)
     pc-2155
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2156
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2157)
     pc-2157
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2158
       (cl:push continue stack)
       (cl:setf pc 2159)
     pc-2159
       (cl:push env stack)
       (cl:setf pc 2160)
     pc-2160
       (cl:push env stack)
       (cl:setf pc 2161)
     pc-2161
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 2162)
     pc-2162
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2163)
     pc-2163
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2164)
     pc-2164
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2165)
     pc-2165
       (cl:when flag (cl:setf pc 2180) (cl:go pc-2180))
     pc-2166
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2167)
     pc-2167
       (cl:when flag (cl:setf pc 2173) (cl:go pc-2173))
     pc-2168
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2169)
     pc-2169
       (cl:when flag (cl:setf pc 2178) (cl:go pc-2178))
     pc-2170
       (cl:setf continue (cl:cons '|compilation-unit| 2181))
       (cl:setf pc 2171)
     pc-2171
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2172)
     pc-2172
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2173
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2174)
     pc-2174
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2175)
     pc-2175
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2176)
     pc-2176
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2177)
     pc-2177
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2178
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2179)
     pc-2179
       (cl:setf pc 2181) (cl:go pc-2181)
     pc-2180
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2181)
     pc-2181
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2182)
     pc-2182
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 2183)
     pc-2183
       (cl:when flag (cl:setf pc 2230) (cl:go pc-2230))
     pc-2184
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 2185)
     pc-2185
       (cl:push proc stack)
       (cl:setf pc 2186)
     pc-2186
       (cl:setf val '|procedure-params|)
       (cl:setf pc 2187)
     pc-2187
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2188)
     pc-2188
       (cl:push argl stack)
       (cl:setf pc 2189)
     pc-2189
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 2190)
     pc-2190
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2191)
     pc-2191
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2192)
     pc-2192
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2193)
     pc-2193
       (cl:when flag (cl:setf pc 2208) (cl:go pc-2208))
     pc-2194
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2195)
     pc-2195
       (cl:when flag (cl:setf pc 2201) (cl:go pc-2201))
     pc-2196
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2197)
     pc-2197
       (cl:when flag (cl:setf pc 2206) (cl:go pc-2206))
     pc-2198
       (cl:setf continue (cl:cons '|compilation-unit| 2209))
       (cl:setf pc 2199)
     pc-2199
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2200)
     pc-2200
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2201
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2202)
     pc-2202
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2203)
     pc-2203
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2204)
     pc-2204
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2205)
     pc-2205
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2206
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2207)
     pc-2207
       (cl:setf pc 2209) (cl:go pc-2209)
     pc-2208
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2209)
     pc-2209
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2210)
     pc-2210
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2211)
     pc-2211
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2212)
     pc-2212
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2213)
     pc-2213
       (cl:when flag (cl:setf pc 2228) (cl:go pc-2228))
     pc-2214
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2215)
     pc-2215
       (cl:when flag (cl:setf pc 2221) (cl:go pc-2221))
     pc-2216
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2217)
     pc-2217
       (cl:when flag (cl:setf pc 2226) (cl:go pc-2226))
     pc-2218
       (cl:setf continue (cl:cons '|compilation-unit| 2231))
       (cl:setf pc 2219)
     pc-2219
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2220)
     pc-2220
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2221
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2222)
     pc-2222
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2223)
     pc-2223
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2224)
     pc-2224
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2225)
     pc-2225
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2226
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2227)
     pc-2227
       (cl:setf pc 2231) (cl:go pc-2231)
     pc-2228
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2229)
     pc-2229
       (cl:setf pc 2231) (cl:go pc-2231)
     pc-2230
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 2231)
     pc-2231
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2232)
     pc-2232
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2233)
     pc-2233
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 2234)
     pc-2234
       (cl:when flag (cl:setf pc 2311) (cl:go pc-2311))
     pc-2235
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 2236)
     pc-2236
       (cl:push continue stack)
       (cl:setf pc 2237)
     pc-2237
       (cl:push proc stack)
       (cl:setf pc 2238)
     pc-2238
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 3 env))
       (cl:setf pc 2239)
     pc-2239
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2240)
     pc-2240
       (cl:push env stack)
       (cl:setf pc 2241)
     pc-2241
       (cl:push argl stack)
       (cl:setf pc 2242)
     pc-2242
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 2243)
     pc-2243
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 2 env))
       (cl:setf pc 2244)
     pc-2244
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2245)
     pc-2245
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2246)
     pc-2246
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2247)
     pc-2247
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2248)
     pc-2248
       (cl:when flag (cl:setf pc 2263) (cl:go pc-2263))
     pc-2249
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2250)
     pc-2250
       (cl:when flag (cl:setf pc 2256) (cl:go pc-2256))
     pc-2251
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2252)
     pc-2252
       (cl:when flag (cl:setf pc 2261) (cl:go pc-2261))
     pc-2253
       (cl:setf continue (cl:cons '|compilation-unit| 2264))
       (cl:setf pc 2254)
     pc-2254
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2255)
     pc-2255
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2256
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2257)
     pc-2257
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2258)
     pc-2258
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2259)
     pc-2259
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2260)
     pc-2260
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2261
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2262)
     pc-2262
       (cl:setf pc 2264) (cl:go pc-2264)
     pc-2263
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2264)
     pc-2264
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2265)
     pc-2265
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2266)
     pc-2266
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2267)
     pc-2267
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 2268)
     pc-2268
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2269)
     pc-2269
       (cl:push argl stack)
       (cl:setf pc 2270)
     pc-2270
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 2271)
     pc-2271
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 2272)
     pc-2272
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2273)
     pc-2273
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2274)
     pc-2274
       (cl:when flag (cl:setf pc 2289) (cl:go pc-2289))
     pc-2275
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2276)
     pc-2276
       (cl:when flag (cl:setf pc 2282) (cl:go pc-2282))
     pc-2277
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2278)
     pc-2278
       (cl:when flag (cl:setf pc 2287) (cl:go pc-2287))
     pc-2279
       (cl:setf continue (cl:cons '|compilation-unit| 2290))
       (cl:setf pc 2280)
     pc-2280
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2281)
     pc-2281
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2282
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2283)
     pc-2283
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2284)
     pc-2284
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2285)
     pc-2285
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2286)
     pc-2286
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2287
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2288)
     pc-2288
       (cl:setf pc 2290) (cl:go pc-2290)
     pc-2289
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2290)
     pc-2290
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2291)
     pc-2291
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2292)
     pc-2292
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2293)
     pc-2293
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2294)
     pc-2294
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2295)
     pc-2295
       (cl:when flag (cl:setf pc 2309) (cl:go pc-2309))
     pc-2296
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2297)
     pc-2297
       (cl:when flag (cl:setf pc 2302) (cl:go pc-2302))
     pc-2298
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2299)
     pc-2299
       (cl:when flag (cl:setf pc 2307) (cl:go pc-2307))
     pc-2300
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2301)
     pc-2301
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2302
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2303)
     pc-2303
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2304)
     pc-2304
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2305)
     pc-2305
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2306)
     pc-2306
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2307
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2308)
     pc-2308
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2309
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2310)
     pc-2310
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2311
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 2312)
     pc-2312
       (cl:push continue stack)
       (cl:setf pc 2313)
     pc-2313
       (cl:push proc stack)
       (cl:setf pc 2314)
     pc-2314
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 3 env))
       (cl:setf pc 2315)
     pc-2315
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2316)
     pc-2316
       (cl:push env stack)
       (cl:setf pc 2317)
     pc-2317
       (cl:push argl stack)
       (cl:setf pc 2318)
     pc-2318
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 2319)
     pc-2319
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 2 env))
       (cl:setf pc 2320)
     pc-2320
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2321)
     pc-2321
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2322)
     pc-2322
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2323)
     pc-2323
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2324)
     pc-2324
       (cl:when flag (cl:setf pc 2339) (cl:go pc-2339))
     pc-2325
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2326)
     pc-2326
       (cl:when flag (cl:setf pc 2332) (cl:go pc-2332))
     pc-2327
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2328)
     pc-2328
       (cl:when flag (cl:setf pc 2337) (cl:go pc-2337))
     pc-2329
       (cl:setf continue (cl:cons '|compilation-unit| 2340))
       (cl:setf pc 2330)
     pc-2330
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2331)
     pc-2331
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2332
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2333)
     pc-2333
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2334)
     pc-2334
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2335)
     pc-2335
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2336)
     pc-2336
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2337
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2338)
     pc-2338
       (cl:setf pc 2340) (cl:go pc-2340)
     pc-2339
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2340)
     pc-2340
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2341)
     pc-2341
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2342)
     pc-2342
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2343)
     pc-2343
       (cl:push env stack)
       (cl:setf pc 2344)
     pc-2344
       (cl:push argl stack)
       (cl:setf pc 2345)
     pc-2345
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|+| env))
       (cl:setf pc 2346)
     pc-2346
       (cl:setf val 1)
       (cl:setf pc 2347)
     pc-2347
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2348)
     pc-2348
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 2349)
     pc-2349
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2350)
     pc-2350
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2351)
     pc-2351
       (cl:when flag (cl:setf pc 2366) (cl:go pc-2366))
     pc-2352
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2353)
     pc-2353
       (cl:when flag (cl:setf pc 2359) (cl:go pc-2359))
     pc-2354
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2355)
     pc-2355
       (cl:when flag (cl:setf pc 2364) (cl:go pc-2364))
     pc-2356
       (cl:setf continue (cl:cons '|compilation-unit| 2367))
       (cl:setf pc 2357)
     pc-2357
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2358)
     pc-2358
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2359
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2360)
     pc-2360
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2361)
     pc-2361
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2362)
     pc-2362
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2363)
     pc-2363
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2364
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2365)
     pc-2365
       (cl:setf pc 2367) (cl:go pc-2367)
     pc-2366
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2367)
     pc-2367
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2368)
     pc-2368
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2369)
     pc-2369
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2370)
     pc-2370
       (cl:push argl stack)
       (cl:setf pc 2371)
     pc-2371
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 2372)
     pc-2372
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 2373)
     pc-2373
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2374)
     pc-2374
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2375)
     pc-2375
       (cl:when flag (cl:setf pc 2390) (cl:go pc-2390))
     pc-2376
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2377)
     pc-2377
       (cl:when flag (cl:setf pc 2383) (cl:go pc-2383))
     pc-2378
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2379)
     pc-2379
       (cl:when flag (cl:setf pc 2388) (cl:go pc-2388))
     pc-2380
       (cl:setf continue (cl:cons '|compilation-unit| 2391))
       (cl:setf pc 2381)
     pc-2381
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2382)
     pc-2382
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2383
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2384)
     pc-2384
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2385)
     pc-2385
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2386)
     pc-2386
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2387)
     pc-2387
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2388
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2389)
     pc-2389
       (cl:setf pc 2391) (cl:go pc-2391)
     pc-2390
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2391)
     pc-2391
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2392)
     pc-2392
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2393)
     pc-2393
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2394)
     pc-2394
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2395)
     pc-2395
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2396)
     pc-2396
       (cl:when flag (cl:setf pc 2410) (cl:go pc-2410))
     pc-2397
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2398)
     pc-2398
       (cl:when flag (cl:setf pc 2403) (cl:go pc-2403))
     pc-2399
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2400)
     pc-2400
       (cl:when flag (cl:setf pc 2408) (cl:go pc-2408))
     pc-2401
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2402)
     pc-2402
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2403
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2404)
     pc-2404
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2405)
     pc-2405
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2406)
     pc-2406
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2407)
     pc-2407
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2408
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2409)
     pc-2409
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2410
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2411)
     pc-2411
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2412
       (cl:push continue stack)
       (cl:setf pc 2413)
     pc-2413
       (cl:push proc stack)
       (cl:setf pc 2414)
     pc-2414
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 2415)
     pc-2415
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2416)
     pc-2416
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2417)
     pc-2417
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2418)
     pc-2418
       (cl:when flag (cl:setf pc 2433) (cl:go pc-2433))
     pc-2419
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2420)
     pc-2420
       (cl:when flag (cl:setf pc 2426) (cl:go pc-2426))
     pc-2421
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2422)
     pc-2422
       (cl:when flag (cl:setf pc 2431) (cl:go pc-2431))
     pc-2423
       (cl:setf continue (cl:cons '|compilation-unit| 2434))
       (cl:setf pc 2424)
     pc-2424
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2425)
     pc-2425
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2426
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2427)
     pc-2427
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2428)
     pc-2428
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2429)
     pc-2429
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2430)
     pc-2430
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2431
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2432)
     pc-2432
       (cl:setf pc 2434) (cl:go pc-2434)
     pc-2433
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2434)
     pc-2434
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2435)
     pc-2435
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2436)
     pc-2436
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2437)
     pc-2437
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2438)
     pc-2438
       (cl:when flag (cl:setf pc 2452) (cl:go pc-2452))
     pc-2439
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2440)
     pc-2440
       (cl:when flag (cl:setf pc 2445) (cl:go pc-2445))
     pc-2441
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2442)
     pc-2442
       (cl:when flag (cl:setf pc 2450) (cl:go pc-2450))
     pc-2443
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2444)
     pc-2444
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2445
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2446)
     pc-2446
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2447)
     pc-2447
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2448)
     pc-2448
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2449)
     pc-2449
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2450
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2451)
     pc-2451
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2452
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2453)
     pc-2453
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2454
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2455)
     pc-2455
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2456)
     pc-2456
       (cl:when flag (cl:setf pc 2470) (cl:go pc-2470))
     pc-2457
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2458)
     pc-2458
       (cl:when flag (cl:setf pc 2463) (cl:go pc-2463))
     pc-2459
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2460)
     pc-2460
       (cl:when flag (cl:setf pc 2468) (cl:go pc-2468))
     pc-2461
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2462)
     pc-2462
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2463
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2464)
     pc-2464
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2465)
     pc-2465
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2466)
     pc-2466
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2467)
     pc-2467
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2468
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2469)
     pc-2469
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2470
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2471)
     pc-2471
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2472
       (cl:setf val cl:nil)
       (cl:setf pc 2473)
     pc-2473
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2474)
     pc-2474
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2475)
     pc-2475
       (cl:when flag (cl:setf pc 2492) (cl:go pc-2492))
     pc-2476
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2477)
     pc-2477
       (cl:when flag (cl:setf pc 2485) (cl:go pc-2485))
     pc-2478
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2479)
     pc-2479
       (cl:when flag (cl:setf pc 2490) (cl:go pc-2490))
     pc-2480
       (cl:setf continue (cl:cons '|compilation-unit| 2483))
       (cl:setf pc 2481)
     pc-2481
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2482)
     pc-2482
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2483
       (cl:setf proc val)
       (cl:setf pc 2484)
     pc-2484
       (cl:setf pc 2493) (cl:go pc-2493)
     pc-2485
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2486)
     pc-2486
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2487)
     pc-2487
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2488)
     pc-2488
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2489)
     pc-2489
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2490
       (cl:setf proc (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2491)
     pc-2491
       (cl:setf pc 2493) (cl:go pc-2493)
     pc-2492
       (cl:setf proc (cl:funcall (get-operation '|apply-primitive-procedure|) proc argl))
       (cl:setf pc 2493)
     pc-2493
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2494)
     pc-2494
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2495)
     pc-2495
       (cl:setf val cl:nil)
       (cl:setf pc 2496)
     pc-2496
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2497)
     pc-2497
       (cl:setf val cl:nil)
       (cl:setf pc 2498)
     pc-2498
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2499)
     pc-2499
       (cl:setf val 0)
       (cl:setf pc 2500)
     pc-2500
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2501)
     pc-2501
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2502)
     pc-2502
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2503)
     pc-2503
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2504)
     pc-2504
       (cl:when flag (cl:setf pc 2518) (cl:go pc-2518))
     pc-2505
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2506)
     pc-2506
       (cl:when flag (cl:setf pc 2511) (cl:go pc-2511))
     pc-2507
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2508)
     pc-2508
       (cl:when flag (cl:setf pc 2516) (cl:go pc-2516))
     pc-2509
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2510)
     pc-2510
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2511
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2512)
     pc-2512
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2513)
     pc-2513
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2514)
     pc-2514
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2515)
     pc-2515
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2516
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2517)
     pc-2517
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2518
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2519)
     pc-2519
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2520
       (cl:funcall (get-operation '|define-variable!|) '|extract-source-map| val env)
       (cl:setf pc 2521)
     pc-2521
       (cl:setf val val)
       (cl:setf pc 2522)
     pc-2522
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 2523)
     pc-2523
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 2525 env))
       (cl:setf pc 2524)
     pc-2524
       (cl:setf pc 2762) (cl:go pc-2762)
     pc-2525
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 2526)
     pc-2526
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|filename| |ext|) argl env 0))
       (cl:setf pc 2527)
     pc-2527
       (cl:setf val "Strip EXT (e.g., \".scm\") from end of FILENAME if present.")
       (cl:setf pc 2528)
     pc-2528
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 2530 env))
       (cl:setf pc 2529)
     pc-2529
       (cl:setf pc 2695) (cl:go pc-2695)
     pc-2530
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 2531)
     pc-2531
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|flen| |elen|) argl env 0))
       (cl:setf pc 2532)
     pc-2532
       (cl:push continue stack)
       (cl:setf pc 2533)
     pc-2533
       (cl:push env stack)
       (cl:setf pc 2534)
     pc-2534
       (cl:push env stack)
       (cl:setf pc 2535)
     pc-2535
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|>| env))
       (cl:setf pc 2536)
     pc-2536
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 2537)
     pc-2537
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2538)
     pc-2538
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2539)
     pc-2539
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2540)
     pc-2540
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2541)
     pc-2541
       (cl:when flag (cl:setf pc 2556) (cl:go pc-2556))
     pc-2542
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2543)
     pc-2543
       (cl:when flag (cl:setf pc 2549) (cl:go pc-2549))
     pc-2544
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2545)
     pc-2545
       (cl:when flag (cl:setf pc 2554) (cl:go pc-2554))
     pc-2546
       (cl:setf continue (cl:cons '|compilation-unit| 2557))
       (cl:setf pc 2547)
     pc-2547
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2548)
     pc-2548
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2549
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2550)
     pc-2550
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2551)
     pc-2551
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2552)
     pc-2552
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2553)
     pc-2553
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2554
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2555)
     pc-2555
       (cl:setf pc 2557) (cl:go pc-2557)
     pc-2556
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2557)
     pc-2557
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2558)
     pc-2558
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 2559)
     pc-2559
       (cl:when flag (cl:setf pc 2637) (cl:go pc-2637))
     pc-2560
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string=?| env))
       (cl:setf pc 2561)
     pc-2561
       (cl:push proc stack)
       (cl:setf pc 2562)
     pc-2562
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 2563)
     pc-2563
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2564)
     pc-2564
       (cl:push argl stack)
       (cl:setf pc 2565)
     pc-2565
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|substring| env))
       (cl:setf pc 2566)
     pc-2566
       (cl:push proc stack)
       (cl:setf pc 2567)
     pc-2567
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2568)
     pc-2568
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2569)
     pc-2569
       (cl:push env stack)
       (cl:setf pc 2570)
     pc-2570
       (cl:push argl stack)
       (cl:setf pc 2571)
     pc-2571
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|-| env))
       (cl:setf pc 2572)
     pc-2572
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 2573)
     pc-2573
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2574)
     pc-2574
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2575)
     pc-2575
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2576)
     pc-2576
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2577)
     pc-2577
       (cl:when flag (cl:setf pc 2592) (cl:go pc-2592))
     pc-2578
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2579)
     pc-2579
       (cl:when flag (cl:setf pc 2585) (cl:go pc-2585))
     pc-2580
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2581)
     pc-2581
       (cl:when flag (cl:setf pc 2590) (cl:go pc-2590))
     pc-2582
       (cl:setf continue (cl:cons '|compilation-unit| 2593))
       (cl:setf pc 2583)
     pc-2583
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2584)
     pc-2584
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2585
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2586)
     pc-2586
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2587)
     pc-2587
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2588)
     pc-2588
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2589)
     pc-2589
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2590
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2591)
     pc-2591
       (cl:setf pc 2593) (cl:go pc-2593)
     pc-2592
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2593)
     pc-2593
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2594)
     pc-2594
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2595)
     pc-2595
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2596)
     pc-2596
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 2597)
     pc-2597
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2598)
     pc-2598
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2599)
     pc-2599
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2600)
     pc-2600
       (cl:when flag (cl:setf pc 2615) (cl:go pc-2615))
     pc-2601
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2602)
     pc-2602
       (cl:when flag (cl:setf pc 2608) (cl:go pc-2608))
     pc-2603
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2604)
     pc-2604
       (cl:when flag (cl:setf pc 2613) (cl:go pc-2613))
     pc-2605
       (cl:setf continue (cl:cons '|compilation-unit| 2616))
       (cl:setf pc 2606)
     pc-2606
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2607)
     pc-2607
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2608
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2609)
     pc-2609
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2610)
     pc-2610
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2611)
     pc-2611
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2612)
     pc-2612
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2613
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2614)
     pc-2614
       (cl:setf pc 2616) (cl:go pc-2616)
     pc-2615
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2616)
     pc-2616
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2617)
     pc-2617
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2618)
     pc-2618
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2619)
     pc-2619
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2620)
     pc-2620
       (cl:when flag (cl:setf pc 2635) (cl:go pc-2635))
     pc-2621
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2622)
     pc-2622
       (cl:when flag (cl:setf pc 2628) (cl:go pc-2628))
     pc-2623
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2624)
     pc-2624
       (cl:when flag (cl:setf pc 2633) (cl:go pc-2633))
     pc-2625
       (cl:setf continue (cl:cons '|compilation-unit| 2638))
       (cl:setf pc 2626)
     pc-2626
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2627)
     pc-2627
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2628
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2629)
     pc-2629
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2630)
     pc-2630
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2631)
     pc-2631
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2632)
     pc-2632
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2633
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2634)
     pc-2634
       (cl:setf pc 2638) (cl:go pc-2638)
     pc-2635
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2636)
     pc-2636
       (cl:setf pc 2638) (cl:go pc-2638)
     pc-2637
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 2638)
     pc-2638
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2639)
     pc-2639
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2640)
     pc-2640
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 2641)
     pc-2641
       (cl:when flag (cl:setf pc 2693) (cl:go pc-2693))
     pc-2642
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|substring| env))
       (cl:setf pc 2643)
     pc-2643
       (cl:push continue stack)
       (cl:setf pc 2644)
     pc-2644
       (cl:push proc stack)
       (cl:setf pc 2645)
     pc-2645
       (cl:push env stack)
       (cl:setf pc 2646)
     pc-2646
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|-| env))
       (cl:setf pc 2647)
     pc-2647
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 2648)
     pc-2648
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2649)
     pc-2649
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2650)
     pc-2650
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2651)
     pc-2651
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2652)
     pc-2652
       (cl:when flag (cl:setf pc 2667) (cl:go pc-2667))
     pc-2653
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2654)
     pc-2654
       (cl:when flag (cl:setf pc 2660) (cl:go pc-2660))
     pc-2655
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2656)
     pc-2656
       (cl:when flag (cl:setf pc 2665) (cl:go pc-2665))
     pc-2657
       (cl:setf continue (cl:cons '|compilation-unit| 2668))
       (cl:setf pc 2658)
     pc-2658
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2659)
     pc-2659
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2660
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2661)
     pc-2661
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2662)
     pc-2662
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2663)
     pc-2663
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2664)
     pc-2664
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2665
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2666)
     pc-2666
       (cl:setf pc 2668) (cl:go pc-2668)
     pc-2667
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2668)
     pc-2668
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2669)
     pc-2669
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2670)
     pc-2670
       (cl:setf val 0)
       (cl:setf pc 2671)
     pc-2671
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2672)
     pc-2672
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 2673)
     pc-2673
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2674)
     pc-2674
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2675)
     pc-2675
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2676)
     pc-2676
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2677)
     pc-2677
       (cl:when flag (cl:setf pc 2691) (cl:go pc-2691))
     pc-2678
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2679)
     pc-2679
       (cl:when flag (cl:setf pc 2684) (cl:go pc-2684))
     pc-2680
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2681)
     pc-2681
       (cl:when flag (cl:setf pc 2689) (cl:go pc-2689))
     pc-2682
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2683)
     pc-2683
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2684
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2685)
     pc-2685
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2686)
     pc-2686
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2687)
     pc-2687
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2688)
     pc-2688
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2689
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2690)
     pc-2690
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2691
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2692)
     pc-2692
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2693
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 2694)
     pc-2694
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2695
       (cl:push continue stack)
       (cl:setf pc 2696)
     pc-2696
       (cl:push proc stack)
       (cl:setf pc 2697)
     pc-2697
       (cl:push env stack)
       (cl:setf pc 2698)
     pc-2698
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string-length| env))
       (cl:setf pc 2699)
     pc-2699
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 2700)
     pc-2700
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2701)
     pc-2701
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2702)
     pc-2702
       (cl:when flag (cl:setf pc 2717) (cl:go pc-2717))
     pc-2703
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2704)
     pc-2704
       (cl:when flag (cl:setf pc 2710) (cl:go pc-2710))
     pc-2705
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2706)
     pc-2706
       (cl:when flag (cl:setf pc 2715) (cl:go pc-2715))
     pc-2707
       (cl:setf continue (cl:cons '|compilation-unit| 2718))
       (cl:setf pc 2708)
     pc-2708
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2709)
     pc-2709
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2710
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2711)
     pc-2711
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2712)
     pc-2712
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2713)
     pc-2713
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2714)
     pc-2714
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2715
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2716)
     pc-2716
       (cl:setf pc 2718) (cl:go pc-2718)
     pc-2717
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2718)
     pc-2718
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2719)
     pc-2719
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2720)
     pc-2720
       (cl:push argl stack)
       (cl:setf pc 2721)
     pc-2721
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string-length| env))
       (cl:setf pc 2722)
     pc-2722
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2723)
     pc-2723
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2724)
     pc-2724
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2725)
     pc-2725
       (cl:when flag (cl:setf pc 2740) (cl:go pc-2740))
     pc-2726
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2727)
     pc-2727
       (cl:when flag (cl:setf pc 2733) (cl:go pc-2733))
     pc-2728
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2729)
     pc-2729
       (cl:when flag (cl:setf pc 2738) (cl:go pc-2738))
     pc-2730
       (cl:setf continue (cl:cons '|compilation-unit| 2741))
       (cl:setf pc 2731)
     pc-2731
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2732)
     pc-2732
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2733
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2734)
     pc-2734
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2735)
     pc-2735
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2736)
     pc-2736
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2737)
     pc-2737
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2738
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2739)
     pc-2739
       (cl:setf pc 2741) (cl:go pc-2741)
     pc-2740
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2741)
     pc-2741
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2742)
     pc-2742
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2743)
     pc-2743
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2744)
     pc-2744
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2745)
     pc-2745
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2746)
     pc-2746
       (cl:when flag (cl:setf pc 2760) (cl:go pc-2760))
     pc-2747
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2748)
     pc-2748
       (cl:when flag (cl:setf pc 2753) (cl:go pc-2753))
     pc-2749
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2750)
     pc-2750
       (cl:when flag (cl:setf pc 2758) (cl:go pc-2758))
     pc-2751
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2752)
     pc-2752
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2753
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2754)
     pc-2754
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2755)
     pc-2755
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2756)
     pc-2756
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2757)
     pc-2757
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2758
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2759)
     pc-2759
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2760
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2761)
     pc-2761
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2762
       (cl:funcall (get-operation '|define-variable!|) '|filename-strip-extension| val env)
       (cl:setf pc 2763)
     pc-2763
       (cl:setf val val)
       (cl:setf pc 2764)
     pc-2764
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 2765)
     pc-2765
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 2767 env))
       (cl:setf pc 2766)
     pc-2766
       (cl:setf pc 3099) (cl:go pc-3099)
     pc-2767
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 2768)
     pc-2768
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|filename|) argl env 0))
       (cl:setf pc 2769)
     pc-2769
       (cl:setf val "Extract the basename from FILENAME (strip directory path).")
       (cl:setf pc 2770)
     pc-2770
       (cl:push continue stack)
       (cl:setf pc 2771)
     pc-2771
       (cl:push env stack)
       (cl:setf pc 2772)
     pc-2772
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 2774 env))
       (cl:setf pc 2773)
     pc-2773
       (cl:setf pc 3009) (cl:go pc-3009)
     pc-2774
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 2775)
     pc-2775
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|loop|) argl env 0))
       (cl:setf pc 2776)
     pc-2776
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 2778 env))
       (cl:setf pc 2777)
     pc-2777
       (cl:setf pc 2785) (cl:go pc-2785)
     pc-2778
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 2779)
     pc-2779
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|g182|) argl env 0))
       (cl:setf pc 2780)
     pc-2780
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2781)
     pc-2781
       (cl:funcall (get-operation '|lexical-set!|) 1 0 val env)
       (cl:setf pc 2782)
     pc-2782
       (cl:setf val val)
       (cl:setf pc 2783)
     pc-2783
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 2784)
     pc-2784
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2785
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 2787 env))
       (cl:setf pc 2786)
     pc-2786
       (cl:setf pc 2991) (cl:go pc-2991)
     pc-2787
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 2788)
     pc-2788
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|i|) argl env 0))
       (cl:setf pc 2789)
     pc-2789
       (cl:push continue stack)
       (cl:setf pc 2790)
     pc-2790
       (cl:push env stack)
       (cl:setf pc 2791)
     pc-2791
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|<| env))
       (cl:setf pc 2792)
     pc-2792
       (cl:setf val 0)
       (cl:setf pc 2793)
     pc-2793
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2794)
     pc-2794
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2795)
     pc-2795
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2796)
     pc-2796
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2797)
     pc-2797
       (cl:when flag (cl:setf pc 2812) (cl:go pc-2812))
     pc-2798
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2799)
     pc-2799
       (cl:when flag (cl:setf pc 2805) (cl:go pc-2805))
     pc-2800
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2801)
     pc-2801
       (cl:when flag (cl:setf pc 2810) (cl:go pc-2810))
     pc-2802
       (cl:setf continue (cl:cons '|compilation-unit| 2813))
       (cl:setf pc 2803)
     pc-2803
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2804)
     pc-2804
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2805
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2806)
     pc-2806
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2807)
     pc-2807
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2808)
     pc-2808
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2809)
     pc-2809
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2810
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2811)
     pc-2811
       (cl:setf pc 2813) (cl:go pc-2813)
     pc-2812
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2813)
     pc-2813
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2814)
     pc-2814
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2815)
     pc-2815
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 2816)
     pc-2816
       (cl:when flag (cl:setf pc 2819) (cl:go pc-2819))
     pc-2817
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 2818)
     pc-2818
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2819
       (cl:push continue stack)
       (cl:setf pc 2820)
     pc-2820
       (cl:push env stack)
       (cl:setf pc 2821)
     pc-2821
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|char=?| env))
       (cl:setf pc 2822)
     pc-2822
       (cl:push proc stack)
       (cl:setf pc 2823)
     pc-2823
       (cl:setf val #\/)
       (cl:setf pc 2824)
     pc-2824
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2825)
     pc-2825
       (cl:push argl stack)
       (cl:setf pc 2826)
     pc-2826
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string-ref| env))
       (cl:setf pc 2827)
     pc-2827
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2828)
     pc-2828
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2829)
     pc-2829
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 2830)
     pc-2830
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2831)
     pc-2831
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2832)
     pc-2832
       (cl:when flag (cl:setf pc 2847) (cl:go pc-2847))
     pc-2833
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2834)
     pc-2834
       (cl:when flag (cl:setf pc 2840) (cl:go pc-2840))
     pc-2835
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2836)
     pc-2836
       (cl:when flag (cl:setf pc 2845) (cl:go pc-2845))
     pc-2837
       (cl:setf continue (cl:cons '|compilation-unit| 2848))
       (cl:setf pc 2838)
     pc-2838
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2839)
     pc-2839
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2840
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2841)
     pc-2841
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2842)
     pc-2842
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2843)
     pc-2843
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2844)
     pc-2844
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2845
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2846)
     pc-2846
       (cl:setf pc 2848) (cl:go pc-2848)
     pc-2847
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2848)
     pc-2848
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2849)
     pc-2849
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2850)
     pc-2850
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2851)
     pc-2851
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2852)
     pc-2852
       (cl:when flag (cl:setf pc 2867) (cl:go pc-2867))
     pc-2853
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2854)
     pc-2854
       (cl:when flag (cl:setf pc 2860) (cl:go pc-2860))
     pc-2855
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2856)
     pc-2856
       (cl:when flag (cl:setf pc 2865) (cl:go pc-2865))
     pc-2857
       (cl:setf continue (cl:cons '|compilation-unit| 2868))
       (cl:setf pc 2858)
     pc-2858
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2859)
     pc-2859
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2860
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2861)
     pc-2861
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2862)
     pc-2862
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2863)
     pc-2863
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2864)
     pc-2864
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2865
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2866)
     pc-2866
       (cl:setf pc 2868) (cl:go pc-2868)
     pc-2867
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2868)
     pc-2868
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2869)
     pc-2869
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2870)
     pc-2870
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 2871)
     pc-2871
       (cl:when flag (cl:setf pc 2946) (cl:go pc-2946))
     pc-2872
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|substring| env))
       (cl:setf pc 2873)
     pc-2873
       (cl:push continue stack)
       (cl:setf pc 2874)
     pc-2874
       (cl:push proc stack)
       (cl:setf pc 2875)
     pc-2875
       (cl:push env stack)
       (cl:setf pc 2876)
     pc-2876
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string-length| env))
       (cl:setf pc 2877)
     pc-2877
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 2878)
     pc-2878
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2879)
     pc-2879
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2880)
     pc-2880
       (cl:when flag (cl:setf pc 2895) (cl:go pc-2895))
     pc-2881
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2882)
     pc-2882
       (cl:when flag (cl:setf pc 2888) (cl:go pc-2888))
     pc-2883
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2884)
     pc-2884
       (cl:when flag (cl:setf pc 2893) (cl:go pc-2893))
     pc-2885
       (cl:setf continue (cl:cons '|compilation-unit| 2896))
       (cl:setf pc 2886)
     pc-2886
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2887)
     pc-2887
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2888
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2889)
     pc-2889
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2890)
     pc-2890
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2891)
     pc-2891
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2892)
     pc-2892
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2893
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2894)
     pc-2894
       (cl:setf pc 2896) (cl:go pc-2896)
     pc-2895
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2896)
     pc-2896
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2897)
     pc-2897
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2898)
     pc-2898
       (cl:push env stack)
       (cl:setf pc 2899)
     pc-2899
       (cl:push argl stack)
       (cl:setf pc 2900)
     pc-2900
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|+| env))
       (cl:setf pc 2901)
     pc-2901
       (cl:setf val 1)
       (cl:setf pc 2902)
     pc-2902
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2903)
     pc-2903
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2904)
     pc-2904
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2905)
     pc-2905
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2906)
     pc-2906
       (cl:when flag (cl:setf pc 2921) (cl:go pc-2921))
     pc-2907
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2908)
     pc-2908
       (cl:when flag (cl:setf pc 2914) (cl:go pc-2914))
     pc-2909
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2910)
     pc-2910
       (cl:when flag (cl:setf pc 2919) (cl:go pc-2919))
     pc-2911
       (cl:setf continue (cl:cons '|compilation-unit| 2922))
       (cl:setf pc 2912)
     pc-2912
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2913)
     pc-2913
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2914
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2915)
     pc-2915
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2916)
     pc-2916
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2917)
     pc-2917
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2918)
     pc-2918
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2919
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2920)
     pc-2920
       (cl:setf pc 2922) (cl:go pc-2922)
     pc-2921
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2922)
     pc-2922
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 2923)
     pc-2923
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2924)
     pc-2924
       (cl:setf env (cl:pop stack))
       (cl:setf pc 2925)
     pc-2925
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 2926)
     pc-2926
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2927)
     pc-2927
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2928)
     pc-2928
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2929)
     pc-2929
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2930)
     pc-2930
       (cl:when flag (cl:setf pc 2944) (cl:go pc-2944))
     pc-2931
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2932)
     pc-2932
       (cl:when flag (cl:setf pc 2937) (cl:go pc-2937))
     pc-2933
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2934)
     pc-2934
       (cl:when flag (cl:setf pc 2942) (cl:go pc-2942))
     pc-2935
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2936)
     pc-2936
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2937
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2938)
     pc-2938
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2939)
     pc-2939
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2940)
     pc-2940
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2941)
     pc-2941
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2942
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2943)
     pc-2943
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2944
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2945)
     pc-2945
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2946
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 2947)
     pc-2947
       (cl:push continue stack)
       (cl:setf pc 2948)
     pc-2948
       (cl:push proc stack)
       (cl:setf pc 2949)
     pc-2949
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|-| env))
       (cl:setf pc 2950)
     pc-2950
       (cl:setf val 1)
       (cl:setf pc 2951)
     pc-2951
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2952)
     pc-2952
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 2953)
     pc-2953
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 2954)
     pc-2954
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2955)
     pc-2955
       (cl:when flag (cl:setf pc 2970) (cl:go pc-2970))
     pc-2956
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2957)
     pc-2957
       (cl:when flag (cl:setf pc 2963) (cl:go pc-2963))
     pc-2958
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2959)
     pc-2959
       (cl:when flag (cl:setf pc 2968) (cl:go pc-2968))
     pc-2960
       (cl:setf continue (cl:cons '|compilation-unit| 2971))
       (cl:setf pc 2961)
     pc-2961
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2962)
     pc-2962
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2963
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2964)
     pc-2964
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2965)
     pc-2965
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2966)
     pc-2966
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2967)
     pc-2967
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2968
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2969)
     pc-2969
       (cl:setf pc 2971) (cl:go pc-2971)
     pc-2970
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2971)
     pc-2971
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2972)
     pc-2972
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 2973)
     pc-2973
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 2974)
     pc-2974
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2975)
     pc-2975
       (cl:when flag (cl:setf pc 2989) (cl:go pc-2989))
     pc-2976
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2977)
     pc-2977
       (cl:when flag (cl:setf pc 2982) (cl:go pc-2982))
     pc-2978
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2979)
     pc-2979
       (cl:when flag (cl:setf pc 2987) (cl:go pc-2987))
     pc-2980
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2981)
     pc-2981
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2982
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 2983)
     pc-2983
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 2984)
     pc-2984
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 2985)
     pc-2985
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 2986)
     pc-2986
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2987
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 2988)
     pc-2988
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2989
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 2990)
     pc-2990
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-2991
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 2992)
     pc-2992
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 2993)
     pc-2993
       (cl:when flag (cl:setf pc 3007) (cl:go pc-3007))
     pc-2994
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 2995)
     pc-2995
       (cl:when flag (cl:setf pc 3000) (cl:go pc-3000))
     pc-2996
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 2997)
     pc-2997
       (cl:when flag (cl:setf pc 3005) (cl:go pc-3005))
     pc-2998
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 2999)
     pc-2999
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3000
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3001)
     pc-3001
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3002)
     pc-3002
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3003)
     pc-3003
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3004)
     pc-3004
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3005
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3006)
     pc-3006
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3007
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3008)
     pc-3008
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3009
       (cl:setf val cl:nil)
       (cl:setf pc 3010)
     pc-3010
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3011)
     pc-3011
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3012)
     pc-3012
       (cl:when flag (cl:setf pc 3029) (cl:go pc-3029))
     pc-3013
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3014)
     pc-3014
       (cl:when flag (cl:setf pc 3022) (cl:go pc-3022))
     pc-3015
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3016)
     pc-3016
       (cl:when flag (cl:setf pc 3027) (cl:go pc-3027))
     pc-3017
       (cl:setf continue (cl:cons '|compilation-unit| 3020))
       (cl:setf pc 3018)
     pc-3018
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3019)
     pc-3019
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3020
       (cl:setf proc val)
       (cl:setf pc 3021)
     pc-3021
       (cl:setf pc 3030) (cl:go pc-3030)
     pc-3022
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3023)
     pc-3023
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3024)
     pc-3024
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3025)
     pc-3025
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3026)
     pc-3026
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3027
       (cl:setf proc (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3028)
     pc-3028
       (cl:setf pc 3030) (cl:go pc-3030)
     pc-3029
       (cl:setf proc (cl:funcall (get-operation '|apply-primitive-procedure|) proc argl))
       (cl:setf pc 3030)
     pc-3030
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3031)
     pc-3031
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3032)
     pc-3032
       (cl:push continue stack)
       (cl:setf pc 3033)
     pc-3033
       (cl:push proc stack)
       (cl:setf pc 3034)
     pc-3034
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|-| env))
       (cl:setf pc 3035)
     pc-3035
       (cl:push proc stack)
       (cl:setf pc 3036)
     pc-3036
       (cl:setf val 1)
       (cl:setf pc 3037)
     pc-3037
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3038)
     pc-3038
       (cl:push argl stack)
       (cl:setf pc 3039)
     pc-3039
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string-length| env))
       (cl:setf pc 3040)
     pc-3040
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3041)
     pc-3041
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3042)
     pc-3042
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3043)
     pc-3043
       (cl:when flag (cl:setf pc 3058) (cl:go pc-3058))
     pc-3044
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3045)
     pc-3045
       (cl:when flag (cl:setf pc 3051) (cl:go pc-3051))
     pc-3046
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3047)
     pc-3047
       (cl:when flag (cl:setf pc 3056) (cl:go pc-3056))
     pc-3048
       (cl:setf continue (cl:cons '|compilation-unit| 3059))
       (cl:setf pc 3049)
     pc-3049
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3050)
     pc-3050
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3051
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3052)
     pc-3052
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3053)
     pc-3053
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3054)
     pc-3054
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3055)
     pc-3055
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3056
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3057)
     pc-3057
       (cl:setf pc 3059) (cl:go pc-3059)
     pc-3058
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3059)
     pc-3059
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 3060)
     pc-3060
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3061)
     pc-3061
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3062)
     pc-3062
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3063)
     pc-3063
       (cl:when flag (cl:setf pc 3078) (cl:go pc-3078))
     pc-3064
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3065)
     pc-3065
       (cl:when flag (cl:setf pc 3071) (cl:go pc-3071))
     pc-3066
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3067)
     pc-3067
       (cl:when flag (cl:setf pc 3076) (cl:go pc-3076))
     pc-3068
       (cl:setf continue (cl:cons '|compilation-unit| 3079))
       (cl:setf pc 3069)
     pc-3069
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3070)
     pc-3070
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3071
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3072)
     pc-3072
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3073)
     pc-3073
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3074)
     pc-3074
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3075)
     pc-3075
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3076
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3077)
     pc-3077
       (cl:setf pc 3079) (cl:go pc-3079)
     pc-3078
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3079)
     pc-3079
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3080)
     pc-3080
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3081)
     pc-3081
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3082)
     pc-3082
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3083)
     pc-3083
       (cl:when flag (cl:setf pc 3097) (cl:go pc-3097))
     pc-3084
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3085)
     pc-3085
       (cl:when flag (cl:setf pc 3090) (cl:go pc-3090))
     pc-3086
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3087)
     pc-3087
       (cl:when flag (cl:setf pc 3095) (cl:go pc-3095))
     pc-3088
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3089)
     pc-3089
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3090
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3091)
     pc-3091
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3092)
     pc-3092
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3093)
     pc-3093
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3094)
     pc-3094
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3095
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3096)
     pc-3096
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3097
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3098)
     pc-3098
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3099
       (cl:funcall (get-operation '|define-variable!|) '|filename-basename| val env)
       (cl:setf pc 3100)
     pc-3100
       (cl:setf val val)
       (cl:setf pc 3101)
     pc-3101
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 3102)
     pc-3102
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 3104 env))
       (cl:setf pc 3103)
     pc-3103
       (cl:setf pc 5375) (cl:go chunk-exit)
     pc-3104
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3105)
     pc-3105
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|filename| |port|) argl env 0))
       (cl:setf pc 3106)
     pc-3106
       (cl:setf val "Compile all forms in FILENAME and write one ecec section (header + instructions)
to PORT. Macro definitions are executed at compile time so subsequent forms can
use them. Returns the space name symbol.")
       (cl:setf pc 3107)
     pc-3107
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 3109 env))
       (cl:setf pc 3108)
     pc-3108
       (cl:setf pc 5287) (cl:go chunk-exit)
     pc-3109
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3110)
     pc-3110
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|space-name|) argl env 0))
       (cl:setf pc 3111)
     pc-3111
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 3113 env))
       (cl:setf pc 3112)
     pc-3112
       (cl:setf pc 5245) (cl:go chunk-exit)
     pc-3113
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3114)
     pc-3114
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|basename|) argl env 0))
       (cl:setf pc 3115)
     pc-3115
       (cl:push continue stack)
       (cl:setf pc 3116)
     pc-3116
       (cl:push env stack)
       (cl:setf pc 3117)
     pc-3117
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%make-hash-table| env))
       (cl:setf pc 3118)
     pc-3118
       (cl:setf argl cl:nil)
       (cl:setf pc 3119)
     pc-3119
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3120)
     pc-3120
       (cl:when flag (cl:setf pc 3135) (cl:go pc-3135))
     pc-3121
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3122)
     pc-3122
       (cl:when flag (cl:setf pc 3128) (cl:go pc-3128))
     pc-3123
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3124)
     pc-3124
       (cl:when flag (cl:setf pc 3133) (cl:go pc-3133))
     pc-3125
       (cl:setf continue (cl:cons '|compilation-unit| 3136))
       (cl:setf pc 3126)
     pc-3126
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3127)
     pc-3127
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3128
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3129)
     pc-3129
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3130)
     pc-3130
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3131)
     pc-3131
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3132)
     pc-3132
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3133
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3134)
     pc-3134
       (cl:setf pc 3136) (cl:go pc-3136)
     pc-3135
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3136)
     pc-3136
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3137)
     pc-3137
       (cl:funcall (get-operation '|set-variable-value!|) '|*source-locations*| val env)
       (cl:setf pc 3138)
     pc-3138
       (cl:setf val val)
       (cl:setf pc 3139)
     pc-3139
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3140)
     pc-3140
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3141)
     pc-3141
       (cl:funcall (get-operation '|set-variable-value!|) '|*source-file-name*| val env)
       (cl:setf pc 3142)
     pc-3142
       (cl:setf val val)
       (cl:setf pc 3143)
     pc-3143
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 3145 env))
       (cl:setf pc 3144)
     pc-3144
       (cl:setf pc 5203) (cl:go chunk-exit)
     pc-3145
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3146)
     pc-3146
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|in|) argl env 3))
       (cl:setf pc 3147)
     pc-3147
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 3149 env))
       (cl:setf pc 3148)
     pc-3148
       (cl:setf pc 3632) (cl:go pc-3632)
     pc-3149
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3150)
     pc-3150
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|expr|) argl env 0))
       (cl:setf pc 3151)
     pc-3151
       (cl:setf val "Transform (define-macro (name params...) body...) into
       (begin (set-macro! 'name (lambda (params...) body...)) 'name)")
       (cl:setf pc 3152)
     pc-3152
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 3154 env))
       (cl:setf pc 3153)
     pc-3153
       (cl:setf pc 3503) (cl:go pc-3503)
     pc-3154
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3155)
     pc-3155
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|name|) argl env 0))
       (cl:setf pc 3156)
     pc-3156
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 3158 env))
       (cl:setf pc 3157)
     pc-3157
       (cl:setf pc 3353) (cl:go pc-3353)
     pc-3158
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3159)
     pc-3159
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|params|) argl env 0))
       (cl:setf pc 3160)
     pc-3160
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 3162 env))
       (cl:setf pc 3161)
     pc-3161
       (cl:setf pc 3311) (cl:go pc-3311)
     pc-3162
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3163)
     pc-3163
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|body|) argl env 0))
       (cl:setf pc 3164)
     pc-3164
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 3165)
     pc-3165
       (cl:push continue stack)
       (cl:setf pc 3166)
     pc-3166
       (cl:push proc stack)
       (cl:setf pc 3167)
     pc-3167
       (cl:push env stack)
       (cl:setf pc 3168)
     pc-3168
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 3169)
     pc-3169
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 3170)
     pc-3170
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3171)
     pc-3171
       (cl:setf val '|quote|)
       (cl:setf pc 3172)
     pc-3172
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3173)
     pc-3173
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3174)
     pc-3174
       (cl:when flag (cl:setf pc 3189) (cl:go pc-3189))
     pc-3175
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3176)
     pc-3176
       (cl:when flag (cl:setf pc 3182) (cl:go pc-3182))
     pc-3177
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3178)
     pc-3178
       (cl:when flag (cl:setf pc 3187) (cl:go pc-3187))
     pc-3179
       (cl:setf continue (cl:cons '|compilation-unit| 3190))
       (cl:setf pc 3180)
     pc-3180
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3181)
     pc-3181
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3182
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3183)
     pc-3183
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3184)
     pc-3184
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3185)
     pc-3185
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3186)
     pc-3186
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3187
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3188)
     pc-3188
       (cl:setf pc 3190) (cl:go pc-3190)
     pc-3189
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3190)
     pc-3190
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3191)
     pc-3191
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3192)
     pc-3192
       (cl:push argl stack)
       (cl:setf pc 3193)
     pc-3193
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 3194)
     pc-3194
       (cl:push proc stack)
       (cl:setf pc 3195)
     pc-3195
       (cl:push env stack)
       (cl:setf pc 3196)
     pc-3196
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 3197)
     pc-3197
       (cl:push proc stack)
       (cl:setf pc 3198)
     pc-3198
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 3199)
     pc-3199
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3200)
     pc-3200
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3201)
     pc-3201
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 3202)
     pc-3202
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3203)
     pc-3203
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3204)
     pc-3204
       (cl:when flag (cl:setf pc 3219) (cl:go pc-3219))
     pc-3205
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3206)
     pc-3206
       (cl:when flag (cl:setf pc 3212) (cl:go pc-3212))
     pc-3207
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3208)
     pc-3208
       (cl:when flag (cl:setf pc 3217) (cl:go pc-3217))
     pc-3209
       (cl:setf continue (cl:cons '|compilation-unit| 3220))
       (cl:setf pc 3210)
     pc-3210
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3211)
     pc-3211
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3212
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3213)
     pc-3213
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3214)
     pc-3214
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3215)
     pc-3215
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3216)
     pc-3216
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3217
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3218)
     pc-3218
       (cl:setf pc 3220) (cl:go pc-3220)
     pc-3219
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3220)
     pc-3220
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3221)
     pc-3221
       (cl:setf val '|lambda|)
       (cl:setf pc 3222)
     pc-3222
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3223)
     pc-3223
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3224)
     pc-3224
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3225)
     pc-3225
       (cl:when flag (cl:setf pc 3240) (cl:go pc-3240))
     pc-3226
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3227)
     pc-3227
       (cl:when flag (cl:setf pc 3233) (cl:go pc-3233))
     pc-3228
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3229)
     pc-3229
       (cl:when flag (cl:setf pc 3238) (cl:go pc-3238))
     pc-3230
       (cl:setf continue (cl:cons '|compilation-unit| 3241))
       (cl:setf pc 3231)
     pc-3231
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3232)
     pc-3232
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3233
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3234)
     pc-3234
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3235)
     pc-3235
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3236)
     pc-3236
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3237)
     pc-3237
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3238
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3239)
     pc-3239
       (cl:setf pc 3241) (cl:go pc-3241)
     pc-3240
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3241)
     pc-3241
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3242)
     pc-3242
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3243)
     pc-3243
       (cl:push argl stack)
       (cl:setf pc 3244)
     pc-3244
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 3245)
     pc-3245
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 3246)
     pc-3246
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3247)
     pc-3247
       (cl:setf val '|quote|)
       (cl:setf pc 3248)
     pc-3248
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3249)
     pc-3249
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3250)
     pc-3250
       (cl:when flag (cl:setf pc 3265) (cl:go pc-3265))
     pc-3251
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3252)
     pc-3252
       (cl:when flag (cl:setf pc 3258) (cl:go pc-3258))
     pc-3253
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3254)
     pc-3254
       (cl:when flag (cl:setf pc 3263) (cl:go pc-3263))
     pc-3255
       (cl:setf continue (cl:cons '|compilation-unit| 3266))
       (cl:setf pc 3256)
     pc-3256
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3257)
     pc-3257
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3258
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3259)
     pc-3259
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3260)
     pc-3260
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3261)
     pc-3261
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3262)
     pc-3262
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3263
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3264)
     pc-3264
       (cl:setf pc 3266) (cl:go pc-3266)
     pc-3265
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3266)
     pc-3266
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 3267)
     pc-3267
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3268)
     pc-3268
       (cl:setf val '|set-macro!|)
       (cl:setf pc 3269)
     pc-3269
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3270)
     pc-3270
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3271)
     pc-3271
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3272)
     pc-3272
       (cl:when flag (cl:setf pc 3287) (cl:go pc-3287))
     pc-3273
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3274)
     pc-3274
       (cl:when flag (cl:setf pc 3280) (cl:go pc-3280))
     pc-3275
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3276)
     pc-3276
       (cl:when flag (cl:setf pc 3285) (cl:go pc-3285))
     pc-3277
       (cl:setf continue (cl:cons '|compilation-unit| 3288))
       (cl:setf pc 3278)
     pc-3278
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3279)
     pc-3279
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3280
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3281)
     pc-3281
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3282)
     pc-3282
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3283)
     pc-3283
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3284)
     pc-3284
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3285
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3286)
     pc-3286
       (cl:setf pc 3288) (cl:go pc-3288)
     pc-3287
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3288)
     pc-3288
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 3289)
     pc-3289
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3290)
     pc-3290
       (cl:setf val '|begin|)
       (cl:setf pc 3291)
     pc-3291
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3292)
     pc-3292
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3293)
     pc-3293
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3294)
     pc-3294
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3295)
     pc-3295
       (cl:when flag (cl:setf pc 3309) (cl:go pc-3309))
     pc-3296
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3297)
     pc-3297
       (cl:when flag (cl:setf pc 3302) (cl:go pc-3302))
     pc-3298
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3299)
     pc-3299
       (cl:when flag (cl:setf pc 3307) (cl:go pc-3307))
     pc-3300
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3301)
     pc-3301
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3302
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3303)
     pc-3303
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3304)
     pc-3304
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3305)
     pc-3305
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3306)
     pc-3306
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3307
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3308)
     pc-3308
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3309
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3310)
     pc-3310
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3311
       (cl:push continue stack)
       (cl:setf pc 3312)
     pc-3312
       (cl:push proc stack)
       (cl:setf pc 3313)
     pc-3313
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cddr| env))
       (cl:setf pc 3314)
     pc-3314
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 3315)
     pc-3315
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3316)
     pc-3316
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3317)
     pc-3317
       (cl:when flag (cl:setf pc 3332) (cl:go pc-3332))
     pc-3318
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3319)
     pc-3319
       (cl:when flag (cl:setf pc 3325) (cl:go pc-3325))
     pc-3320
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3321)
     pc-3321
       (cl:when flag (cl:setf pc 3330) (cl:go pc-3330))
     pc-3322
       (cl:setf continue (cl:cons '|compilation-unit| 3333))
       (cl:setf pc 3323)
     pc-3323
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3324)
     pc-3324
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3325
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3326)
     pc-3326
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3327)
     pc-3327
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3328)
     pc-3328
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3329)
     pc-3329
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3330
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3331)
     pc-3331
       (cl:setf pc 3333) (cl:go pc-3333)
     pc-3332
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3333)
     pc-3333
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3334)
     pc-3334
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3335)
     pc-3335
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3336)
     pc-3336
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3337)
     pc-3337
       (cl:when flag (cl:setf pc 3351) (cl:go pc-3351))
     pc-3338
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3339)
     pc-3339
       (cl:when flag (cl:setf pc 3344) (cl:go pc-3344))
     pc-3340
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3341)
     pc-3341
       (cl:when flag (cl:setf pc 3349) (cl:go pc-3349))
     pc-3342
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3343)
     pc-3343
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3344
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3345)
     pc-3345
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3346)
     pc-3346
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3347)
     pc-3347
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3348)
     pc-3348
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3349
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3350)
     pc-3350
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3351
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3352)
     pc-3352
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3353
       (cl:push continue stack)
       (cl:setf pc 3354)
     pc-3354
       (cl:push proc stack)
       (cl:setf pc 3355)
     pc-3355
       (cl:push env stack)
       (cl:setf pc 3356)
     pc-3356
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 3357)
     pc-3357
       (cl:push proc stack)
       (cl:setf pc 3358)
     pc-3358
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 3359)
     pc-3359
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 3360)
     pc-3360
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3361)
     pc-3361
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3362)
     pc-3362
       (cl:when flag (cl:setf pc 3377) (cl:go pc-3377))
     pc-3363
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3364)
     pc-3364
       (cl:when flag (cl:setf pc 3370) (cl:go pc-3370))
     pc-3365
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3366)
     pc-3366
       (cl:when flag (cl:setf pc 3375) (cl:go pc-3375))
     pc-3367
       (cl:setf continue (cl:cons '|compilation-unit| 3378))
       (cl:setf pc 3368)
     pc-3368
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3369)
     pc-3369
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3370
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3371)
     pc-3371
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3372)
     pc-3372
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3373)
     pc-3373
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3374)
     pc-3374
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3375
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3376)
     pc-3376
       (cl:setf pc 3378) (cl:go pc-3378)
     pc-3377
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3378)
     pc-3378
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3379)
     pc-3379
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3380)
     pc-3380
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3381)
     pc-3381
       (cl:when flag (cl:setf pc 3396) (cl:go pc-3396))
     pc-3382
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3383)
     pc-3383
       (cl:when flag (cl:setf pc 3389) (cl:go pc-3389))
     pc-3384
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3385)
     pc-3385
       (cl:when flag (cl:setf pc 3394) (cl:go pc-3394))
     pc-3386
       (cl:setf continue (cl:cons '|compilation-unit| 3397))
       (cl:setf pc 3387)
     pc-3387
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3388)
     pc-3388
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3389
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3390)
     pc-3390
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3391)
     pc-3391
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3392)
     pc-3392
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3393)
     pc-3393
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3394
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3395)
     pc-3395
       (cl:setf pc 3397) (cl:go pc-3397)
     pc-3396
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3397)
     pc-3397
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3398)
     pc-3398
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 3399)
     pc-3399
       (cl:when flag (cl:setf pc 3442) (cl:go pc-3442))
     pc-3400
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 3401)
     pc-3401
       (cl:push proc stack)
       (cl:setf pc 3402)
     pc-3402
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 3403)
     pc-3403
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 3404)
     pc-3404
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3405)
     pc-3405
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3406)
     pc-3406
       (cl:when flag (cl:setf pc 3421) (cl:go pc-3421))
     pc-3407
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3408)
     pc-3408
       (cl:when flag (cl:setf pc 3414) (cl:go pc-3414))
     pc-3409
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3410)
     pc-3410
       (cl:when flag (cl:setf pc 3419) (cl:go pc-3419))
     pc-3411
       (cl:setf continue (cl:cons '|compilation-unit| 3422))
       (cl:setf pc 3412)
     pc-3412
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3413)
     pc-3413
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3414
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3415)
     pc-3415
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3416)
     pc-3416
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3417)
     pc-3417
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3418)
     pc-3418
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3419
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3420)
     pc-3420
       (cl:setf pc 3422) (cl:go pc-3422)
     pc-3421
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3422)
     pc-3422
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3423)
     pc-3423
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3424)
     pc-3424
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3425)
     pc-3425
       (cl:when flag (cl:setf pc 3440) (cl:go pc-3440))
     pc-3426
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3427)
     pc-3427
       (cl:when flag (cl:setf pc 3433) (cl:go pc-3433))
     pc-3428
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3429)
     pc-3429
       (cl:when flag (cl:setf pc 3438) (cl:go pc-3438))
     pc-3430
       (cl:setf continue (cl:cons '|compilation-unit| 3483))
       (cl:setf pc 3431)
     pc-3431
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3432)
     pc-3432
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3433
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3434)
     pc-3434
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3435)
     pc-3435
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3436)
     pc-3436
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3437)
     pc-3437
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3438
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3439)
     pc-3439
       (cl:setf pc 3483) (cl:go pc-3483)
     pc-3440
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3441)
     pc-3441
       (cl:setf pc 3483) (cl:go pc-3483)
     pc-3442
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 3443)
     pc-3443
       (cl:push proc stack)
       (cl:setf pc 3444)
     pc-3444
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 3445)
     pc-3445
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 3446)
     pc-3446
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3447)
     pc-3447
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3448)
     pc-3448
       (cl:when flag (cl:setf pc 3463) (cl:go pc-3463))
     pc-3449
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3450)
     pc-3450
       (cl:when flag (cl:setf pc 3456) (cl:go pc-3456))
     pc-3451
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3452)
     pc-3452
       (cl:when flag (cl:setf pc 3461) (cl:go pc-3461))
     pc-3453
       (cl:setf continue (cl:cons '|compilation-unit| 3464))
       (cl:setf pc 3454)
     pc-3454
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3455)
     pc-3455
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3456
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3457)
     pc-3457
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3458)
     pc-3458
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3459)
     pc-3459
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3460)
     pc-3460
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3461
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3462)
     pc-3462
       (cl:setf pc 3464) (cl:go pc-3464)
     pc-3463
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3464)
     pc-3464
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3465)
     pc-3465
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3466)
     pc-3466
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3467)
     pc-3467
       (cl:when flag (cl:setf pc 3482) (cl:go pc-3482))
     pc-3468
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3469)
     pc-3469
       (cl:when flag (cl:setf pc 3475) (cl:go pc-3475))
     pc-3470
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3471)
     pc-3471
       (cl:when flag (cl:setf pc 3480) (cl:go pc-3480))
     pc-3472
       (cl:setf continue (cl:cons '|compilation-unit| 3483))
       (cl:setf pc 3473)
     pc-3473
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3474)
     pc-3474
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3475
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3476)
     pc-3476
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3477)
     pc-3477
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3478)
     pc-3478
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3479)
     pc-3479
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3480
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3481)
     pc-3481
       (cl:setf pc 3483) (cl:go pc-3483)
     pc-3482
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3483)
     pc-3483
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3484)
     pc-3484
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3485)
     pc-3485
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3486)
     pc-3486
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3487)
     pc-3487
       (cl:when flag (cl:setf pc 3501) (cl:go pc-3501))
     pc-3488
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3489)
     pc-3489
       (cl:when flag (cl:setf pc 3494) (cl:go pc-3494))
     pc-3490
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3491)
     pc-3491
       (cl:when flag (cl:setf pc 3499) (cl:go pc-3499))
     pc-3492
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3493)
     pc-3493
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3494
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3495)
     pc-3495
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3496)
     pc-3496
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3497)
     pc-3497
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3498)
     pc-3498
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3499
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3500)
     pc-3500
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3501
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3502)
     pc-3502
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3503
       (cl:push continue stack)
       (cl:setf pc 3504)
     pc-3504
       (cl:push proc stack)
       (cl:setf pc 3505)
     pc-3505
       (cl:push env stack)
       (cl:setf pc 3506)
     pc-3506
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 3507)
     pc-3507
       (cl:push proc stack)
       (cl:setf pc 3508)
     pc-3508
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 3509)
     pc-3509
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3510)
     pc-3510
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3511)
     pc-3511
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3512)
     pc-3512
       (cl:when flag (cl:setf pc 3527) (cl:go pc-3527))
     pc-3513
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3514)
     pc-3514
       (cl:when flag (cl:setf pc 3520) (cl:go pc-3520))
     pc-3515
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3516)
     pc-3516
       (cl:when flag (cl:setf pc 3525) (cl:go pc-3525))
     pc-3517
       (cl:setf continue (cl:cons '|compilation-unit| 3528))
       (cl:setf pc 3518)
     pc-3518
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3519)
     pc-3519
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3520
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3521)
     pc-3521
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3522)
     pc-3522
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3523)
     pc-3523
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3524)
     pc-3524
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3525
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3526)
     pc-3526
       (cl:setf pc 3528) (cl:go pc-3528)
     pc-3527
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3528)
     pc-3528
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3529)
     pc-3529
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3530)
     pc-3530
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3531)
     pc-3531
       (cl:when flag (cl:setf pc 3546) (cl:go pc-3546))
     pc-3532
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3533)
     pc-3533
       (cl:when flag (cl:setf pc 3539) (cl:go pc-3539))
     pc-3534
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3535)
     pc-3535
       (cl:when flag (cl:setf pc 3544) (cl:go pc-3544))
     pc-3536
       (cl:setf continue (cl:cons '|compilation-unit| 3547))
       (cl:setf pc 3537)
     pc-3537
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3538)
     pc-3538
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3539
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3540)
     pc-3540
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3541)
     pc-3541
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3542)
     pc-3542
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3543)
     pc-3543
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3544
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3545)
     pc-3545
       (cl:setf pc 3547) (cl:go pc-3547)
     pc-3546
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3547)
     pc-3547
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3548)
     pc-3548
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 3549)
     pc-3549
       (cl:when flag (cl:setf pc 3592) (cl:go pc-3592))
     pc-3550
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 3551)
     pc-3551
       (cl:push proc stack)
       (cl:setf pc 3552)
     pc-3552
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 3553)
     pc-3553
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3554)
     pc-3554
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3555)
     pc-3555
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3556)
     pc-3556
       (cl:when flag (cl:setf pc 3571) (cl:go pc-3571))
     pc-3557
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3558)
     pc-3558
       (cl:when flag (cl:setf pc 3564) (cl:go pc-3564))
     pc-3559
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3560)
     pc-3560
       (cl:when flag (cl:setf pc 3569) (cl:go pc-3569))
     pc-3561
       (cl:setf continue (cl:cons '|compilation-unit| 3572))
       (cl:setf pc 3562)
     pc-3562
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3563)
     pc-3563
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3564
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3565)
     pc-3565
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3566)
     pc-3566
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3567)
     pc-3567
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3568)
     pc-3568
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3569
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3570)
     pc-3570
       (cl:setf pc 3572) (cl:go pc-3572)
     pc-3571
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3572)
     pc-3572
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3573)
     pc-3573
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3574)
     pc-3574
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3575)
     pc-3575
       (cl:when flag (cl:setf pc 3590) (cl:go pc-3590))
     pc-3576
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3577)
     pc-3577
       (cl:when flag (cl:setf pc 3583) (cl:go pc-3583))
     pc-3578
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3579)
     pc-3579
       (cl:when flag (cl:setf pc 3588) (cl:go pc-3588))
     pc-3580
       (cl:setf continue (cl:cons '|compilation-unit| 3612))
       (cl:setf pc 3581)
     pc-3581
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3582)
     pc-3582
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3583
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3584)
     pc-3584
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3585)
     pc-3585
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3586)
     pc-3586
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3587)
     pc-3587
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3588
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3589)
     pc-3589
       (cl:setf pc 3612) (cl:go pc-3612)
     pc-3590
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3591)
     pc-3591
       (cl:setf pc 3612) (cl:go pc-3612)
     pc-3592
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 3593)
     pc-3593
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3594)
     pc-3594
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3595)
     pc-3595
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3596)
     pc-3596
       (cl:when flag (cl:setf pc 3611) (cl:go pc-3611))
     pc-3597
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3598)
     pc-3598
       (cl:when flag (cl:setf pc 3604) (cl:go pc-3604))
     pc-3599
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3600)
     pc-3600
       (cl:when flag (cl:setf pc 3609) (cl:go pc-3609))
     pc-3601
       (cl:setf continue (cl:cons '|compilation-unit| 3612))
       (cl:setf pc 3602)
     pc-3602
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3603)
     pc-3603
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3604
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3605)
     pc-3605
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3606)
     pc-3606
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3607)
     pc-3607
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3608)
     pc-3608
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3609
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3610)
     pc-3610
       (cl:setf pc 3612) (cl:go pc-3612)
     pc-3611
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3612)
     pc-3612
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3613)
     pc-3613
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3614)
     pc-3614
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3615)
     pc-3615
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3616)
     pc-3616
       (cl:when flag (cl:setf pc 3630) (cl:go pc-3630))
     pc-3617
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3618)
     pc-3618
       (cl:when flag (cl:setf pc 3623) (cl:go pc-3623))
     pc-3619
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3620)
     pc-3620
       (cl:when flag (cl:setf pc 3628) (cl:go pc-3628))
     pc-3621
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3622)
     pc-3622
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3623
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3624)
     pc-3624
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3625)
     pc-3625
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3626)
     pc-3626
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3627)
     pc-3627
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3628
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3629)
     pc-3629
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3630
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3631)
     pc-3631
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3632
       (cl:funcall (get-operation '|lexical-set!|) 0 1 val env)
       (cl:setf pc 3633)
     pc-3633
       (cl:setf val val)
       (cl:setf pc 3634)
     pc-3634
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 3636 env))
       (cl:setf pc 3635)
     pc-3635
       (cl:setf pc 3812) (cl:go pc-3812)
     pc-3636
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3637)
     pc-3637
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|expr|) argl env 0))
       (cl:setf pc 3638)
     pc-3638
       (cl:setf val "If EXPR is (define-syntax ...), expand to (define-macro ...) so it gets
       compile-time execution and load-time set-macro! treatment.")
       (cl:setf pc 3639)
     pc-3639
       (cl:push continue stack)
       (cl:setf pc 3640)
     pc-3640
       (cl:push env stack)
       (cl:setf pc 3641)
     pc-3641
       (cl:push env stack)
       (cl:setf pc 3642)
     pc-3642
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 3643)
     pc-3643
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3644)
     pc-3644
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3645)
     pc-3645
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3646)
     pc-3646
       (cl:when flag (cl:setf pc 3661) (cl:go pc-3661))
     pc-3647
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3648)
     pc-3648
       (cl:when flag (cl:setf pc 3654) (cl:go pc-3654))
     pc-3649
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3650)
     pc-3650
       (cl:when flag (cl:setf pc 3659) (cl:go pc-3659))
     pc-3651
       (cl:setf continue (cl:cons '|compilation-unit| 3662))
       (cl:setf pc 3652)
     pc-3652
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3653)
     pc-3653
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3654
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3655)
     pc-3655
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3656)
     pc-3656
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3657)
     pc-3657
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3658)
     pc-3658
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3659
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3660)
     pc-3660
       (cl:setf pc 3662) (cl:go pc-3662)
     pc-3661
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3662)
     pc-3662
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3663)
     pc-3663
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 3664)
     pc-3664
       (cl:when flag (cl:setf pc 3737) (cl:go pc-3737))
     pc-3665
       (cl:push env stack)
       (cl:setf pc 3666)
     pc-3666
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 3667)
     pc-3667
       (cl:push proc stack)
       (cl:setf pc 3668)
     pc-3668
       (cl:setf val '|define-syntax|)
       (cl:setf pc 3669)
     pc-3669
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3670)
     pc-3670
       (cl:push argl stack)
       (cl:setf pc 3671)
     pc-3671
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 3672)
     pc-3672
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3673)
     pc-3673
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3674)
     pc-3674
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3675)
     pc-3675
       (cl:when flag (cl:setf pc 3690) (cl:go pc-3690))
     pc-3676
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3677)
     pc-3677
       (cl:when flag (cl:setf pc 3683) (cl:go pc-3683))
     pc-3678
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3679)
     pc-3679
       (cl:when flag (cl:setf pc 3688) (cl:go pc-3688))
     pc-3680
       (cl:setf continue (cl:cons '|compilation-unit| 3691))
       (cl:setf pc 3681)
     pc-3681
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3682)
     pc-3682
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3683
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3684)
     pc-3684
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3685)
     pc-3685
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3686)
     pc-3686
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3687)
     pc-3687
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3688
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3689)
     pc-3689
       (cl:setf pc 3691) (cl:go pc-3691)
     pc-3690
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3691)
     pc-3691
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 3692)
     pc-3692
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3693)
     pc-3693
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3694)
     pc-3694
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3695)
     pc-3695
       (cl:when flag (cl:setf pc 3710) (cl:go pc-3710))
     pc-3696
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3697)
     pc-3697
       (cl:when flag (cl:setf pc 3703) (cl:go pc-3703))
     pc-3698
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3699)
     pc-3699
       (cl:when flag (cl:setf pc 3708) (cl:go pc-3708))
     pc-3700
       (cl:setf continue (cl:cons '|compilation-unit| 3711))
       (cl:setf pc 3701)
     pc-3701
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3702)
     pc-3702
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3703
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3704)
     pc-3704
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3705)
     pc-3705
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3706)
     pc-3706
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3707)
     pc-3707
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3708
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3709)
     pc-3709
       (cl:setf pc 3711) (cl:go pc-3711)
     pc-3710
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3711)
     pc-3711
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3712)
     pc-3712
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 3713)
     pc-3713
       (cl:when flag (cl:setf pc 3735) (cl:go pc-3735))
     pc-3714
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|get-macro| env))
       (cl:setf pc 3715)
     pc-3715
       (cl:setf val '|define-syntax|)
       (cl:setf pc 3716)
     pc-3716
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3717)
     pc-3717
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3718)
     pc-3718
       (cl:when flag (cl:setf pc 3733) (cl:go pc-3733))
     pc-3719
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3720)
     pc-3720
       (cl:when flag (cl:setf pc 3726) (cl:go pc-3726))
     pc-3721
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3722)
     pc-3722
       (cl:when flag (cl:setf pc 3731) (cl:go pc-3731))
     pc-3723
       (cl:setf continue (cl:cons '|compilation-unit| 3738))
       (cl:setf pc 3724)
     pc-3724
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3725)
     pc-3725
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3726
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3727)
     pc-3727
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3728)
     pc-3728
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3729)
     pc-3729
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3730)
     pc-3730
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3731
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3732)
     pc-3732
       (cl:setf pc 3738) (cl:go pc-3738)
     pc-3733
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3734)
     pc-3734
       (cl:setf pc 3738) (cl:go pc-3738)
     pc-3735
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 3736)
     pc-3736
       (cl:setf pc 3738) (cl:go pc-3738)
     pc-3737
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 3738)
     pc-3738
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3739)
     pc-3739
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3740)
     pc-3740
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 3741)
     pc-3741
       (cl:when flag (cl:setf pc 3810) (cl:go pc-3810))
     pc-3742
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|mc-expand-macro-at-compile-time| env))
       (cl:setf pc 3743)
     pc-3743
       (cl:push continue stack)
       (cl:setf pc 3744)
     pc-3744
       (cl:push proc stack)
       (cl:setf pc 3745)
     pc-3745
       (cl:push env stack)
       (cl:setf pc 3746)
     pc-3746
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 3747)
     pc-3747
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3748)
     pc-3748
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3749)
     pc-3749
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3750)
     pc-3750
       (cl:when flag (cl:setf pc 3765) (cl:go pc-3765))
     pc-3751
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3752)
     pc-3752
       (cl:when flag (cl:setf pc 3758) (cl:go pc-3758))
     pc-3753
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3754)
     pc-3754
       (cl:when flag (cl:setf pc 3763) (cl:go pc-3763))
     pc-3755
       (cl:setf continue (cl:cons '|compilation-unit| 3766))
       (cl:setf pc 3756)
     pc-3756
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3757)
     pc-3757
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3758
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3759)
     pc-3759
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3760)
     pc-3760
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3761)
     pc-3761
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3762)
     pc-3762
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3763
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3764)
     pc-3764
       (cl:setf pc 3766) (cl:go pc-3766)
     pc-3765
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3766)
     pc-3766
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3767)
     pc-3767
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3768)
     pc-3768
       (cl:push argl stack)
       (cl:setf pc 3769)
     pc-3769
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|get-macro| env))
       (cl:setf pc 3770)
     pc-3770
       (cl:setf val '|define-syntax|)
       (cl:setf pc 3771)
     pc-3771
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3772)
     pc-3772
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3773)
     pc-3773
       (cl:when flag (cl:setf pc 3788) (cl:go pc-3788))
     pc-3774
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3775)
     pc-3775
       (cl:when flag (cl:setf pc 3781) (cl:go pc-3781))
     pc-3776
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3777)
     pc-3777
       (cl:when flag (cl:setf pc 3786) (cl:go pc-3786))
     pc-3778
       (cl:setf continue (cl:cons '|compilation-unit| 3789))
       (cl:setf pc 3779)
     pc-3779
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3780)
     pc-3780
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3781
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3782)
     pc-3782
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3783)
     pc-3783
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3784)
     pc-3784
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3785)
     pc-3785
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3786
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3787)
     pc-3787
       (cl:setf pc 3789) (cl:go pc-3789)
     pc-3788
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3789)
     pc-3789
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 3790)
     pc-3790
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3791)
     pc-3791
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3792)
     pc-3792
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3793)
     pc-3793
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3794)
     pc-3794
       (cl:when flag (cl:setf pc 3808) (cl:go pc-3808))
     pc-3795
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3796)
     pc-3796
       (cl:when flag (cl:setf pc 3801) (cl:go pc-3801))
     pc-3797
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3798)
     pc-3798
       (cl:when flag (cl:setf pc 3806) (cl:go pc-3806))
     pc-3799
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3800)
     pc-3800
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3801
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3802)
     pc-3802
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3803)
     pc-3803
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3804)
     pc-3804
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3805)
     pc-3805
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3806
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3807)
     pc-3807
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3808
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3809)
     pc-3809
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3810
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3811)
     pc-3811
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3812
       (cl:funcall (get-operation '|lexical-set!|) 0 2 val env)
       (cl:setf pc 3813)
     pc-3813
       (cl:setf val val)
       (cl:setf pc 3814)
     pc-3814
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 3816 env))
       (cl:setf pc 3815)
     pc-3815
       (cl:setf pc 4438) (cl:go chunk-exit)
     pc-3816
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3817)
     pc-3817
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|units| |macros|) argl env 0))
       (cl:setf pc 3818)
     pc-3818
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 3820 env))
       (cl:setf pc 3819)
     pc-3819
       (cl:setf pc 4375) (cl:go chunk-exit)
     pc-3820
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 3821)
     pc-3821
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|expr|) argl env 0))
       (cl:setf pc 3822)
     pc-3822
       (cl:push continue stack)
       (cl:setf pc 3823)
     pc-3823
       (cl:push env stack)
       (cl:setf pc 3824)
     pc-3824
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eof?| env))
       (cl:setf pc 3825)
     pc-3825
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3826)
     pc-3826
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3827)
     pc-3827
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3828)
     pc-3828
       (cl:when flag (cl:setf pc 3843) (cl:go pc-3843))
     pc-3829
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3830)
     pc-3830
       (cl:when flag (cl:setf pc 3836) (cl:go pc-3836))
     pc-3831
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3832)
     pc-3832
       (cl:when flag (cl:setf pc 3841) (cl:go pc-3841))
     pc-3833
       (cl:setf continue (cl:cons '|compilation-unit| 3844))
       (cl:setf pc 3834)
     pc-3834
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3835)
     pc-3835
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3836
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3837)
     pc-3837
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3838)
     pc-3838
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3839)
     pc-3839
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3840)
     pc-3840
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3841
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3842)
     pc-3842
       (cl:setf pc 3844) (cl:go pc-3844)
     pc-3843
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3844)
     pc-3844
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3845)
     pc-3845
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3846)
     pc-3846
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 3847)
     pc-3847
       (cl:when flag (cl:setf pc 3894) (cl:go pc-3894))
     pc-3848
       (cl:push continue stack)
       (cl:setf pc 3849)
     pc-3849
       (cl:push env stack)
       (cl:setf pc 3850)
     pc-3850
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|close-input-port| env))
       (cl:setf pc 3851)
     pc-3851
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 3852)
     pc-3852
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3853)
     pc-3853
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3854)
     pc-3854
       (cl:when flag (cl:setf pc 3869) (cl:go pc-3869))
     pc-3855
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3856)
     pc-3856
       (cl:when flag (cl:setf pc 3862) (cl:go pc-3862))
     pc-3857
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3858)
     pc-3858
       (cl:when flag (cl:setf pc 3867) (cl:go pc-3867))
     pc-3859
       (cl:setf continue (cl:cons '|compilation-unit| 3870))
       (cl:setf pc 3860)
     pc-3860
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3861)
     pc-3861
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3862
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3863)
     pc-3863
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3864)
     pc-3864
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3865)
     pc-3865
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3866)
     pc-3866
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3867
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3868)
     pc-3868
       (cl:setf pc 3870) (cl:go pc-3870)
     pc-3869
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3870)
     pc-3870
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3871)
     pc-3871
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3872)
     pc-3872
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 3873)
     pc-3873
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 3874)
     pc-3874
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3875)
     pc-3875
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 3876)
     pc-3876
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3877)
     pc-3877
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3878)
     pc-3878
       (cl:when flag (cl:setf pc 3892) (cl:go pc-3892))
     pc-3879
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3880)
     pc-3880
       (cl:when flag (cl:setf pc 3885) (cl:go pc-3885))
     pc-3881
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3882)
     pc-3882
       (cl:when flag (cl:setf pc 3890) (cl:go pc-3890))
     pc-3883
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3884)
     pc-3884
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3885
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3886)
     pc-3886
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3887)
     pc-3887
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3888)
     pc-3888
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3889)
     pc-3889
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3890
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3891)
     pc-3891
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3892
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3893)
     pc-3893
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3894
       (cl:push continue stack)
       (cl:setf pc 3895)
     pc-3895
       (cl:push env stack)
       (cl:setf pc 3896)
     pc-3896
       (cl:push env stack)
       (cl:setf pc 3897)
     pc-3897
       (cl:push env stack)
       (cl:setf pc 3898)
     pc-3898
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 3899)
     pc-3899
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3900)
     pc-3900
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3901)
     pc-3901
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3902)
     pc-3902
       (cl:when flag (cl:setf pc 3917) (cl:go pc-3917))
     pc-3903
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3904)
     pc-3904
       (cl:when flag (cl:setf pc 3910) (cl:go pc-3910))
     pc-3905
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3906)
     pc-3906
       (cl:when flag (cl:setf pc 3915) (cl:go pc-3915))
     pc-3907
       (cl:setf continue (cl:cons '|compilation-unit| 3918))
       (cl:setf pc 3908)
     pc-3908
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3909)
     pc-3909
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3910
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3911)
     pc-3911
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3912)
     pc-3912
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3913)
     pc-3913
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3914)
     pc-3914
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3915
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3916)
     pc-3916
       (cl:setf pc 3918) (cl:go pc-3918)
     pc-3917
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3918)
     pc-3918
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3919)
     pc-3919
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 3920)
     pc-3920
       (cl:when flag (cl:setf pc 3967) (cl:go pc-3967))
     pc-3921
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 3922)
     pc-3922
       (cl:push proc stack)
       (cl:setf pc 3923)
     pc-3923
       (cl:setf val '|define-macro|)
       (cl:setf pc 3924)
     pc-3924
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3925)
     pc-3925
       (cl:push argl stack)
       (cl:setf pc 3926)
     pc-3926
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 3927)
     pc-3927
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3928)
     pc-3928
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3929)
     pc-3929
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3930)
     pc-3930
       (cl:when flag (cl:setf pc 3945) (cl:go pc-3945))
     pc-3931
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3932)
     pc-3932
       (cl:when flag (cl:setf pc 3938) (cl:go pc-3938))
     pc-3933
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3934)
     pc-3934
       (cl:when flag (cl:setf pc 3943) (cl:go pc-3943))
     pc-3935
       (cl:setf continue (cl:cons '|compilation-unit| 3946))
       (cl:setf pc 3936)
     pc-3936
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3937)
     pc-3937
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3938
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3939)
     pc-3939
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3940)
     pc-3940
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3941)
     pc-3941
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3942)
     pc-3942
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3943
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3944)
     pc-3944
       (cl:setf pc 3946) (cl:go pc-3946)
     pc-3945
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3946)
     pc-3946
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 3947)
     pc-3947
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 3948)
     pc-3948
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 3949)
     pc-3949
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3950)
     pc-3950
       (cl:when flag (cl:setf pc 3965) (cl:go pc-3965))
     pc-3951
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3952)
     pc-3952
       (cl:when flag (cl:setf pc 3958) (cl:go pc-3958))
     pc-3953
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3954)
     pc-3954
       (cl:when flag (cl:setf pc 3963) (cl:go pc-3963))
     pc-3955
       (cl:setf continue (cl:cons '|compilation-unit| 3968))
       (cl:setf pc 3956)
     pc-3956
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3957)
     pc-3957
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3958
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3959)
     pc-3959
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3960)
     pc-3960
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3961)
     pc-3961
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3962)
     pc-3962
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3963
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3964)
     pc-3964
       (cl:setf pc 3968) (cl:go pc-3968)
     pc-3965
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3966)
     pc-3966
       (cl:setf pc 3968) (cl:go pc-3968)
     pc-3967
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 3968)
     pc-3968
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3969)
     pc-3969
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 3970)
     pc-3970
       (cl:when flag (cl:setf pc 3992) (cl:go pc-3992))
     pc-3971
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|mc-compile-and-go| env))
       (cl:setf pc 3972)
     pc-3972
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 3973)
     pc-3973
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 3974)
     pc-3974
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 3975)
     pc-3975
       (cl:when flag (cl:setf pc 3990) (cl:go pc-3990))
     pc-3976
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 3977)
     pc-3977
       (cl:when flag (cl:setf pc 3983) (cl:go pc-3983))
     pc-3978
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 3979)
     pc-3979
       (cl:when flag (cl:setf pc 3988) (cl:go pc-3988))
     pc-3980
       (cl:setf continue (cl:cons '|compilation-unit| 3993))
       (cl:setf pc 3981)
     pc-3981
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 3982)
     pc-3982
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3983
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 3984)
     pc-3984
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 3985)
     pc-3985
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 3986)
     pc-3986
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 3987)
     pc-3987
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-3988
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 3989)
     pc-3989
       (cl:setf pc 3993) (cl:go pc-3993)
     pc-3990
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 3991)
     pc-3991
       (cl:setf pc 3993) (cl:go pc-3993)
     pc-3992
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 3993)
     pc-3993
       (cl:setf env (cl:pop stack))
       (cl:setf pc 3994)
     pc-3994
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 3995)
     pc-3995
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 2 3 env))
       (cl:setf pc 3996)
     pc-3996
       (cl:push continue stack)
       (cl:setf pc 3997)
     pc-3997
       (cl:push proc stack)
       (cl:setf pc 3998)
     pc-3998
       (cl:push env stack)
       (cl:setf pc 3999)
     pc-3999
       (cl:push env stack)
       (cl:setf pc 4000)
     pc-4000
       (cl:push env stack)
       (cl:setf pc 4001)
     pc-4001
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 4002)
     pc-4002
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4003)
     pc-4003
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4004)
     pc-4004
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4005)
     pc-4005
       (cl:when flag (cl:setf pc 4020) (cl:go pc-4020))
     pc-4006
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4007)
     pc-4007
       (cl:when flag (cl:setf pc 4013) (cl:go pc-4013))
     pc-4008
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4009)
     pc-4009
       (cl:when flag (cl:setf pc 4018) (cl:go pc-4018))
     pc-4010
       (cl:setf continue (cl:cons '|compilation-unit| 4021))
       (cl:setf pc 4011)
     pc-4011
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4012)
     pc-4012
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4013
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4014)
     pc-4014
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4015)
     pc-4015
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4016)
     pc-4016
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4017)
     pc-4017
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4018
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4019)
     pc-4019
       (cl:setf pc 4021) (cl:go pc-4021)
     pc-4020
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4021)
     pc-4021
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4022)
     pc-4022
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 4023)
     pc-4023
       (cl:when flag (cl:setf pc 4070) (cl:go pc-4070))
     pc-4024
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 4025)
     pc-4025
       (cl:push proc stack)
       (cl:setf pc 4026)
     pc-4026
       (cl:setf val '|define-macro|)
       (cl:setf pc 4027)
     pc-4027
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4028)
     pc-4028
       (cl:push argl stack)
       (cl:setf pc 4029)
     pc-4029
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 4030)
     pc-4030
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4031)
     pc-4031
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4032)
     pc-4032
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4033)
     pc-4033
       (cl:when flag (cl:setf pc 4048) (cl:go pc-4048))
     pc-4034
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4035)
     pc-4035
       (cl:when flag (cl:setf pc 4041) (cl:go pc-4041))
     pc-4036
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4037)
     pc-4037
       (cl:when flag (cl:setf pc 4046) (cl:go pc-4046))
     pc-4038
       (cl:setf continue (cl:cons '|compilation-unit| 4049))
       (cl:setf pc 4039)
     pc-4039
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4040)
     pc-4040
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4041
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4042)
     pc-4042
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4043)
     pc-4043
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4044)
     pc-4044
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4045)
     pc-4045
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4046
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4047)
     pc-4047
       (cl:setf pc 4049) (cl:go pc-4049)
     pc-4048
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4049)
     pc-4049
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 4050)
     pc-4050
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4051)
     pc-4051
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4052)
     pc-4052
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4053)
     pc-4053
       (cl:when flag (cl:setf pc 4068) (cl:go pc-4068))
     pc-4054
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4055)
     pc-4055
       (cl:when flag (cl:setf pc 4061) (cl:go pc-4061))
     pc-4056
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4057)
     pc-4057
       (cl:when flag (cl:setf pc 4066) (cl:go pc-4066))
     pc-4058
       (cl:setf continue (cl:cons '|compilation-unit| 4071))
       (cl:setf pc 4059)
     pc-4059
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4060)
     pc-4060
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4061
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4062)
     pc-4062
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4063)
     pc-4063
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4064)
     pc-4064
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4065)
     pc-4065
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4066
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4067)
     pc-4067
       (cl:setf pc 4071) (cl:go pc-4071)
     pc-4068
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4069)
     pc-4069
       (cl:setf pc 4071) (cl:go pc-4071)
     pc-4070
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 4071)
     pc-4071
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4072)
     pc-4072
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 4073)
     pc-4073
       (cl:when flag (cl:setf pc 4207) (cl:go chunk-exit))
     pc-4074
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 4075)
     pc-4075
       (cl:push proc stack)
       (cl:setf pc 4076)
     pc-4076
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 4077)
     pc-4077
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4078)
     pc-4078
       (cl:push argl stack)
       (cl:setf pc 4079)
     pc-4079
       (cl:push env stack)
       (cl:setf pc 4080)
     pc-4080
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 4081)
     pc-4081
       (cl:push proc stack)
       (cl:setf pc 4082)
     pc-4082
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 4083)
     pc-4083
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4084)
     pc-4084
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4085)
     pc-4085
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4086)
     pc-4086
       (cl:when flag (cl:setf pc 4101) (cl:go chunk-exit))
     pc-4087
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4088)
     pc-4088
       (cl:when flag (cl:setf pc 4094) (cl:go pc-4094))
     pc-4089
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4090)
     pc-4090
       (cl:when flag (cl:setf pc 4099) (cl:go chunk-exit))
     pc-4091
       (cl:setf continue (cl:cons '|compilation-unit| 4102))
       (cl:setf pc 4092)
     pc-4092
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4093)
     pc-4093
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4094
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4095)
     pc-4095
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4096)
     chunk-exit)
    (cl:values pc val env proc argl continue stack bail)))

(defun zone-compilation-unit-chunk-1 (initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)
  (cl:let ((pc initial-pc)
           (val initial-val)
           (env initial-env)
           (proc initial-proc)
           (argl initial-argl)
           (continue initial-continue)
           (stack initial-stack)
           (flag cl:nil)
           (bail cl:nil))
    (cl:declare (cl:type cl:fixnum pc) (cl:ignorable flag bail))
    (cl:tagbody
     (cl:cond
       ((cl:< pc 4352)
        (cl:case pc
          (4096 (cl:go pc-4096))
          (4097 (cl:go pc-4097))
          (4098 (cl:go pc-4098))
          (4099 (cl:go pc-4099))
          (4100 (cl:go pc-4100))
          (4101 (cl:go pc-4101))
          (4102 (cl:go pc-4102))
          (4103 (cl:go pc-4103))
          (4104 (cl:go pc-4104))
          (4105 (cl:go pc-4105))
          (4106 (cl:go pc-4106))
          (4107 (cl:go pc-4107))
          (4108 (cl:go pc-4108))
          (4109 (cl:go pc-4109))
          (4110 (cl:go pc-4110))
          (4111 (cl:go pc-4111))
          (4112 (cl:go pc-4112))
          (4113 (cl:go pc-4113))
          (4114 (cl:go pc-4114))
          (4115 (cl:go pc-4115))
          (4116 (cl:go pc-4116))
          (4117 (cl:go pc-4117))
          (4118 (cl:go pc-4118))
          (4119 (cl:go pc-4119))
          (4120 (cl:go pc-4120))
          (4121 (cl:go pc-4121))
          (4122 (cl:go pc-4122))
          (4123 (cl:go pc-4123))
          (4124 (cl:go pc-4124))
          (4125 (cl:go pc-4125))
          (4126 (cl:go pc-4126))
          (4127 (cl:go pc-4127))
          (4128 (cl:go pc-4128))
          (4129 (cl:go pc-4129))
          (4130 (cl:go pc-4130))
          (4131 (cl:go pc-4131))
          (4132 (cl:go pc-4132))
          (4133 (cl:go pc-4133))
          (4134 (cl:go pc-4134))
          (4135 (cl:go pc-4135))
          (4136 (cl:go pc-4136))
          (4137 (cl:go pc-4137))
          (4138 (cl:go pc-4138))
          (4139 (cl:go pc-4139))
          (4140 (cl:go pc-4140))
          (4141 (cl:go pc-4141))
          (4142 (cl:go pc-4142))
          (4143 (cl:go pc-4143))
          (4144 (cl:go pc-4144))
          (4145 (cl:go pc-4145))
          (4146 (cl:go pc-4146))
          (4147 (cl:go pc-4147))
          (4148 (cl:go pc-4148))
          (4149 (cl:go pc-4149))
          (4150 (cl:go pc-4150))
          (4151 (cl:go pc-4151))
          (4152 (cl:go pc-4152))
          (4153 (cl:go pc-4153))
          (4154 (cl:go pc-4154))
          (4155 (cl:go pc-4155))
          (4156 (cl:go pc-4156))
          (4157 (cl:go pc-4157))
          (4158 (cl:go pc-4158))
          (4159 (cl:go pc-4159))
          (4160 (cl:go pc-4160))
          (4161 (cl:go pc-4161))
          (4162 (cl:go pc-4162))
          (4163 (cl:go pc-4163))
          (4164 (cl:go pc-4164))
          (4165 (cl:go pc-4165))
          (4166 (cl:go pc-4166))
          (4167 (cl:go pc-4167))
          (4168 (cl:go pc-4168))
          (4169 (cl:go pc-4169))
          (4170 (cl:go pc-4170))
          (4171 (cl:go pc-4171))
          (4172 (cl:go pc-4172))
          (4173 (cl:go pc-4173))
          (4174 (cl:go pc-4174))
          (4175 (cl:go pc-4175))
          (4176 (cl:go pc-4176))
          (4177 (cl:go pc-4177))
          (4178 (cl:go pc-4178))
          (4179 (cl:go pc-4179))
          (4180 (cl:go pc-4180))
          (4181 (cl:go pc-4181))
          (4182 (cl:go pc-4182))
          (4183 (cl:go pc-4183))
          (4184 (cl:go pc-4184))
          (4185 (cl:go pc-4185))
          (4186 (cl:go pc-4186))
          (4187 (cl:go pc-4187))
          (4188 (cl:go pc-4188))
          (4189 (cl:go pc-4189))
          (4190 (cl:go pc-4190))
          (4191 (cl:go pc-4191))
          (4192 (cl:go pc-4192))
          (4193 (cl:go pc-4193))
          (4194 (cl:go pc-4194))
          (4195 (cl:go pc-4195))
          (4196 (cl:go pc-4196))
          (4197 (cl:go pc-4197))
          (4198 (cl:go pc-4198))
          (4199 (cl:go pc-4199))
          (4200 (cl:go pc-4200))
          (4201 (cl:go pc-4201))
          (4202 (cl:go pc-4202))
          (4203 (cl:go pc-4203))
          (4204 (cl:go pc-4204))
          (4205 (cl:go pc-4205))
          (4206 (cl:go pc-4206))
          (4207 (cl:go pc-4207))
          (4208 (cl:go pc-4208))
          (4209 (cl:go pc-4209))
          (4210 (cl:go pc-4210))
          (4211 (cl:go pc-4211))
          (4212 (cl:go pc-4212))
          (4213 (cl:go pc-4213))
          (4214 (cl:go pc-4214))
          (4215 (cl:go pc-4215))
          (4216 (cl:go pc-4216))
          (4217 (cl:go pc-4217))
          (4218 (cl:go pc-4218))
          (4219 (cl:go pc-4219))
          (4220 (cl:go pc-4220))
          (4221 (cl:go pc-4221))
          (4222 (cl:go pc-4222))
          (4223 (cl:go pc-4223))
          (4224 (cl:go pc-4224))
          (4225 (cl:go pc-4225))
          (4226 (cl:go pc-4226))
          (4227 (cl:go pc-4227))
          (4228 (cl:go pc-4228))
          (4229 (cl:go pc-4229))
          (4230 (cl:go pc-4230))
          (4231 (cl:go pc-4231))
          (4232 (cl:go pc-4232))
          (4233 (cl:go pc-4233))
          (4234 (cl:go pc-4234))
          (4235 (cl:go pc-4235))
          (4236 (cl:go pc-4236))
          (4237 (cl:go pc-4237))
          (4238 (cl:go pc-4238))
          (4239 (cl:go pc-4239))
          (4240 (cl:go pc-4240))
          (4241 (cl:go pc-4241))
          (4242 (cl:go pc-4242))
          (4243 (cl:go pc-4243))
          (4244 (cl:go pc-4244))
          (4245 (cl:go pc-4245))
          (4246 (cl:go pc-4246))
          (4247 (cl:go pc-4247))
          (4248 (cl:go pc-4248))
          (4249 (cl:go pc-4249))
          (4250 (cl:go pc-4250))
          (4251 (cl:go pc-4251))
          (4252 (cl:go pc-4252))
          (4253 (cl:go pc-4253))
          (4254 (cl:go pc-4254))
          (4255 (cl:go pc-4255))
          (4256 (cl:go pc-4256))
          (4257 (cl:go pc-4257))
          (4258 (cl:go pc-4258))
          (4259 (cl:go pc-4259))
          (4260 (cl:go pc-4260))
          (4261 (cl:go pc-4261))
          (4262 (cl:go pc-4262))
          (4263 (cl:go pc-4263))
          (4264 (cl:go pc-4264))
          (4265 (cl:go pc-4265))
          (4266 (cl:go pc-4266))
          (4267 (cl:go pc-4267))
          (4268 (cl:go pc-4268))
          (4269 (cl:go pc-4269))
          (4270 (cl:go pc-4270))
          (4271 (cl:go pc-4271))
          (4272 (cl:go pc-4272))
          (4273 (cl:go pc-4273))
          (4274 (cl:go pc-4274))
          (4275 (cl:go pc-4275))
          (4276 (cl:go pc-4276))
          (4277 (cl:go pc-4277))
          (4278 (cl:go pc-4278))
          (4279 (cl:go pc-4279))
          (4280 (cl:go pc-4280))
          (4281 (cl:go pc-4281))
          (4282 (cl:go pc-4282))
          (4283 (cl:go pc-4283))
          (4284 (cl:go pc-4284))
          (4285 (cl:go pc-4285))
          (4286 (cl:go pc-4286))
          (4287 (cl:go pc-4287))
          (4288 (cl:go pc-4288))
          (4289 (cl:go pc-4289))
          (4290 (cl:go pc-4290))
          (4291 (cl:go pc-4291))
          (4292 (cl:go pc-4292))
          (4293 (cl:go pc-4293))
          (4294 (cl:go pc-4294))
          (4295 (cl:go pc-4295))
          (4296 (cl:go pc-4296))
          (4297 (cl:go pc-4297))
          (4298 (cl:go pc-4298))
          (4299 (cl:go pc-4299))
          (4300 (cl:go pc-4300))
          (4301 (cl:go pc-4301))
          (4302 (cl:go pc-4302))
          (4303 (cl:go pc-4303))
          (4304 (cl:go pc-4304))
          (4305 (cl:go pc-4305))
          (4306 (cl:go pc-4306))
          (4307 (cl:go pc-4307))
          (4308 (cl:go pc-4308))
          (4309 (cl:go pc-4309))
          (4310 (cl:go pc-4310))
          (4311 (cl:go pc-4311))
          (4312 (cl:go pc-4312))
          (4313 (cl:go pc-4313))
          (4314 (cl:go pc-4314))
          (4315 (cl:go pc-4315))
          (4316 (cl:go pc-4316))
          (4317 (cl:go pc-4317))
          (4318 (cl:go pc-4318))
          (4319 (cl:go pc-4319))
          (4320 (cl:go pc-4320))
          (4321 (cl:go pc-4321))
          (4322 (cl:go pc-4322))
          (4323 (cl:go pc-4323))
          (4324 (cl:go pc-4324))
          (4325 (cl:go pc-4325))
          (4326 (cl:go pc-4326))
          (4327 (cl:go pc-4327))
          (4328 (cl:go pc-4328))
          (4329 (cl:go pc-4329))
          (4330 (cl:go pc-4330))
          (4331 (cl:go pc-4331))
          (4332 (cl:go pc-4332))
          (4333 (cl:go pc-4333))
          (4334 (cl:go pc-4334))
          (4335 (cl:go pc-4335))
          (4336 (cl:go pc-4336))
          (4337 (cl:go pc-4337))
          (4338 (cl:go pc-4338))
          (4339 (cl:go pc-4339))
          (4340 (cl:go pc-4340))
          (4341 (cl:go pc-4341))
          (4342 (cl:go pc-4342))
          (4343 (cl:go pc-4343))
          (4344 (cl:go pc-4344))
          (4345 (cl:go pc-4345))
          (4346 (cl:go pc-4346))
          (4347 (cl:go pc-4347))
          (4348 (cl:go pc-4348))
          (4349 (cl:go pc-4349))
          (4350 (cl:go pc-4350))
          (4351 (cl:go pc-4351))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 4608)
        (cl:case pc
          (4352 (cl:go pc-4352))
          (4353 (cl:go pc-4353))
          (4354 (cl:go pc-4354))
          (4355 (cl:go pc-4355))
          (4356 (cl:go pc-4356))
          (4357 (cl:go pc-4357))
          (4358 (cl:go pc-4358))
          (4359 (cl:go pc-4359))
          (4360 (cl:go pc-4360))
          (4361 (cl:go pc-4361))
          (4362 (cl:go pc-4362))
          (4363 (cl:go pc-4363))
          (4364 (cl:go pc-4364))
          (4365 (cl:go pc-4365))
          (4366 (cl:go pc-4366))
          (4367 (cl:go pc-4367))
          (4368 (cl:go pc-4368))
          (4369 (cl:go pc-4369))
          (4370 (cl:go pc-4370))
          (4371 (cl:go pc-4371))
          (4372 (cl:go pc-4372))
          (4373 (cl:go pc-4373))
          (4374 (cl:go pc-4374))
          (4375 (cl:go pc-4375))
          (4376 (cl:go pc-4376))
          (4377 (cl:go pc-4377))
          (4378 (cl:go pc-4378))
          (4379 (cl:go pc-4379))
          (4380 (cl:go pc-4380))
          (4381 (cl:go pc-4381))
          (4382 (cl:go pc-4382))
          (4383 (cl:go pc-4383))
          (4384 (cl:go pc-4384))
          (4385 (cl:go pc-4385))
          (4386 (cl:go pc-4386))
          (4387 (cl:go pc-4387))
          (4388 (cl:go pc-4388))
          (4389 (cl:go pc-4389))
          (4390 (cl:go pc-4390))
          (4391 (cl:go pc-4391))
          (4392 (cl:go pc-4392))
          (4393 (cl:go pc-4393))
          (4394 (cl:go pc-4394))
          (4395 (cl:go pc-4395))
          (4396 (cl:go pc-4396))
          (4397 (cl:go pc-4397))
          (4398 (cl:go pc-4398))
          (4399 (cl:go pc-4399))
          (4400 (cl:go pc-4400))
          (4401 (cl:go pc-4401))
          (4402 (cl:go pc-4402))
          (4403 (cl:go pc-4403))
          (4404 (cl:go pc-4404))
          (4405 (cl:go pc-4405))
          (4406 (cl:go pc-4406))
          (4407 (cl:go pc-4407))
          (4408 (cl:go pc-4408))
          (4409 (cl:go pc-4409))
          (4410 (cl:go pc-4410))
          (4411 (cl:go pc-4411))
          (4412 (cl:go pc-4412))
          (4413 (cl:go pc-4413))
          (4414 (cl:go pc-4414))
          (4415 (cl:go pc-4415))
          (4416 (cl:go pc-4416))
          (4417 (cl:go pc-4417))
          (4418 (cl:go pc-4418))
          (4419 (cl:go pc-4419))
          (4420 (cl:go pc-4420))
          (4421 (cl:go pc-4421))
          (4422 (cl:go pc-4422))
          (4423 (cl:go pc-4423))
          (4424 (cl:go pc-4424))
          (4425 (cl:go pc-4425))
          (4426 (cl:go pc-4426))
          (4427 (cl:go pc-4427))
          (4428 (cl:go pc-4428))
          (4429 (cl:go pc-4429))
          (4430 (cl:go pc-4430))
          (4431 (cl:go pc-4431))
          (4432 (cl:go pc-4432))
          (4433 (cl:go pc-4433))
          (4434 (cl:go pc-4434))
          (4435 (cl:go pc-4435))
          (4436 (cl:go pc-4436))
          (4437 (cl:go pc-4437))
          (4438 (cl:go pc-4438))
          (4439 (cl:go pc-4439))
          (4440 (cl:go pc-4440))
          (4441 (cl:go pc-4441))
          (4442 (cl:go pc-4442))
          (4443 (cl:go pc-4443))
          (4444 (cl:go pc-4444))
          (4445 (cl:go pc-4445))
          (4446 (cl:go pc-4446))
          (4447 (cl:go pc-4447))
          (4448 (cl:go pc-4448))
          (4449 (cl:go pc-4449))
          (4450 (cl:go pc-4450))
          (4451 (cl:go pc-4451))
          (4452 (cl:go pc-4452))
          (4453 (cl:go pc-4453))
          (4454 (cl:go pc-4454))
          (4455 (cl:go pc-4455))
          (4456 (cl:go pc-4456))
          (4457 (cl:go pc-4457))
          (4458 (cl:go pc-4458))
          (4459 (cl:go pc-4459))
          (4460 (cl:go pc-4460))
          (4461 (cl:go pc-4461))
          (4462 (cl:go pc-4462))
          (4463 (cl:go pc-4463))
          (4464 (cl:go pc-4464))
          (4465 (cl:go pc-4465))
          (4466 (cl:go pc-4466))
          (4467 (cl:go pc-4467))
          (4468 (cl:go pc-4468))
          (4469 (cl:go pc-4469))
          (4470 (cl:go pc-4470))
          (4471 (cl:go pc-4471))
          (4472 (cl:go pc-4472))
          (4473 (cl:go pc-4473))
          (4474 (cl:go pc-4474))
          (4475 (cl:go pc-4475))
          (4476 (cl:go pc-4476))
          (4477 (cl:go pc-4477))
          (4478 (cl:go pc-4478))
          (4479 (cl:go pc-4479))
          (4480 (cl:go pc-4480))
          (4481 (cl:go pc-4481))
          (4482 (cl:go pc-4482))
          (4483 (cl:go pc-4483))
          (4484 (cl:go pc-4484))
          (4485 (cl:go pc-4485))
          (4486 (cl:go pc-4486))
          (4487 (cl:go pc-4487))
          (4488 (cl:go pc-4488))
          (4489 (cl:go pc-4489))
          (4490 (cl:go pc-4490))
          (4491 (cl:go pc-4491))
          (4492 (cl:go pc-4492))
          (4493 (cl:go pc-4493))
          (4494 (cl:go pc-4494))
          (4495 (cl:go pc-4495))
          (4496 (cl:go pc-4496))
          (4497 (cl:go pc-4497))
          (4498 (cl:go pc-4498))
          (4499 (cl:go pc-4499))
          (4500 (cl:go pc-4500))
          (4501 (cl:go pc-4501))
          (4502 (cl:go pc-4502))
          (4503 (cl:go pc-4503))
          (4504 (cl:go pc-4504))
          (4505 (cl:go pc-4505))
          (4506 (cl:go pc-4506))
          (4507 (cl:go pc-4507))
          (4508 (cl:go pc-4508))
          (4509 (cl:go pc-4509))
          (4510 (cl:go pc-4510))
          (4511 (cl:go pc-4511))
          (4512 (cl:go pc-4512))
          (4513 (cl:go pc-4513))
          (4514 (cl:go pc-4514))
          (4515 (cl:go pc-4515))
          (4516 (cl:go pc-4516))
          (4517 (cl:go pc-4517))
          (4518 (cl:go pc-4518))
          (4519 (cl:go pc-4519))
          (4520 (cl:go pc-4520))
          (4521 (cl:go pc-4521))
          (4522 (cl:go pc-4522))
          (4523 (cl:go pc-4523))
          (4524 (cl:go pc-4524))
          (4525 (cl:go pc-4525))
          (4526 (cl:go pc-4526))
          (4527 (cl:go pc-4527))
          (4528 (cl:go pc-4528))
          (4529 (cl:go pc-4529))
          (4530 (cl:go pc-4530))
          (4531 (cl:go pc-4531))
          (4532 (cl:go pc-4532))
          (4533 (cl:go pc-4533))
          (4534 (cl:go pc-4534))
          (4535 (cl:go pc-4535))
          (4536 (cl:go pc-4536))
          (4537 (cl:go pc-4537))
          (4538 (cl:go pc-4538))
          (4539 (cl:go pc-4539))
          (4540 (cl:go pc-4540))
          (4541 (cl:go pc-4541))
          (4542 (cl:go pc-4542))
          (4543 (cl:go pc-4543))
          (4544 (cl:go pc-4544))
          (4545 (cl:go pc-4545))
          (4546 (cl:go pc-4546))
          (4547 (cl:go pc-4547))
          (4548 (cl:go pc-4548))
          (4549 (cl:go pc-4549))
          (4550 (cl:go pc-4550))
          (4551 (cl:go pc-4551))
          (4552 (cl:go pc-4552))
          (4553 (cl:go pc-4553))
          (4554 (cl:go pc-4554))
          (4555 (cl:go pc-4555))
          (4556 (cl:go pc-4556))
          (4557 (cl:go pc-4557))
          (4558 (cl:go pc-4558))
          (4559 (cl:go pc-4559))
          (4560 (cl:go pc-4560))
          (4561 (cl:go pc-4561))
          (4562 (cl:go pc-4562))
          (4563 (cl:go pc-4563))
          (4564 (cl:go pc-4564))
          (4565 (cl:go pc-4565))
          (4566 (cl:go pc-4566))
          (4567 (cl:go pc-4567))
          (4568 (cl:go pc-4568))
          (4569 (cl:go pc-4569))
          (4570 (cl:go pc-4570))
          (4571 (cl:go pc-4571))
          (4572 (cl:go pc-4572))
          (4573 (cl:go pc-4573))
          (4574 (cl:go pc-4574))
          (4575 (cl:go pc-4575))
          (4576 (cl:go pc-4576))
          (4577 (cl:go pc-4577))
          (4578 (cl:go pc-4578))
          (4579 (cl:go pc-4579))
          (4580 (cl:go pc-4580))
          (4581 (cl:go pc-4581))
          (4582 (cl:go pc-4582))
          (4583 (cl:go pc-4583))
          (4584 (cl:go pc-4584))
          (4585 (cl:go pc-4585))
          (4586 (cl:go pc-4586))
          (4587 (cl:go pc-4587))
          (4588 (cl:go pc-4588))
          (4589 (cl:go pc-4589))
          (4590 (cl:go pc-4590))
          (4591 (cl:go pc-4591))
          (4592 (cl:go pc-4592))
          (4593 (cl:go pc-4593))
          (4594 (cl:go pc-4594))
          (4595 (cl:go pc-4595))
          (4596 (cl:go pc-4596))
          (4597 (cl:go pc-4597))
          (4598 (cl:go pc-4598))
          (4599 (cl:go pc-4599))
          (4600 (cl:go pc-4600))
          (4601 (cl:go pc-4601))
          (4602 (cl:go pc-4602))
          (4603 (cl:go pc-4603))
          (4604 (cl:go pc-4604))
          (4605 (cl:go pc-4605))
          (4606 (cl:go pc-4606))
          (4607 (cl:go pc-4607))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 4864)
        (cl:case pc
          (4608 (cl:go pc-4608))
          (4609 (cl:go pc-4609))
          (4610 (cl:go pc-4610))
          (4611 (cl:go pc-4611))
          (4612 (cl:go pc-4612))
          (4613 (cl:go pc-4613))
          (4614 (cl:go pc-4614))
          (4615 (cl:go pc-4615))
          (4616 (cl:go pc-4616))
          (4617 (cl:go pc-4617))
          (4618 (cl:go pc-4618))
          (4619 (cl:go pc-4619))
          (4620 (cl:go pc-4620))
          (4621 (cl:go pc-4621))
          (4622 (cl:go pc-4622))
          (4623 (cl:go pc-4623))
          (4624 (cl:go pc-4624))
          (4625 (cl:go pc-4625))
          (4626 (cl:go pc-4626))
          (4627 (cl:go pc-4627))
          (4628 (cl:go pc-4628))
          (4629 (cl:go pc-4629))
          (4630 (cl:go pc-4630))
          (4631 (cl:go pc-4631))
          (4632 (cl:go pc-4632))
          (4633 (cl:go pc-4633))
          (4634 (cl:go pc-4634))
          (4635 (cl:go pc-4635))
          (4636 (cl:go pc-4636))
          (4637 (cl:go pc-4637))
          (4638 (cl:go pc-4638))
          (4639 (cl:go pc-4639))
          (4640 (cl:go pc-4640))
          (4641 (cl:go pc-4641))
          (4642 (cl:go pc-4642))
          (4643 (cl:go pc-4643))
          (4644 (cl:go pc-4644))
          (4645 (cl:go pc-4645))
          (4646 (cl:go pc-4646))
          (4647 (cl:go pc-4647))
          (4648 (cl:go pc-4648))
          (4649 (cl:go pc-4649))
          (4650 (cl:go pc-4650))
          (4651 (cl:go pc-4651))
          (4652 (cl:go pc-4652))
          (4653 (cl:go pc-4653))
          (4654 (cl:go pc-4654))
          (4655 (cl:go pc-4655))
          (4656 (cl:go pc-4656))
          (4657 (cl:go pc-4657))
          (4658 (cl:go pc-4658))
          (4659 (cl:go pc-4659))
          (4660 (cl:go pc-4660))
          (4661 (cl:go pc-4661))
          (4662 (cl:go pc-4662))
          (4663 (cl:go pc-4663))
          (4664 (cl:go pc-4664))
          (4665 (cl:go pc-4665))
          (4666 (cl:go pc-4666))
          (4667 (cl:go pc-4667))
          (4668 (cl:go pc-4668))
          (4669 (cl:go pc-4669))
          (4670 (cl:go pc-4670))
          (4671 (cl:go pc-4671))
          (4672 (cl:go pc-4672))
          (4673 (cl:go pc-4673))
          (4674 (cl:go pc-4674))
          (4675 (cl:go pc-4675))
          (4676 (cl:go pc-4676))
          (4677 (cl:go pc-4677))
          (4678 (cl:go pc-4678))
          (4679 (cl:go pc-4679))
          (4680 (cl:go pc-4680))
          (4681 (cl:go pc-4681))
          (4682 (cl:go pc-4682))
          (4683 (cl:go pc-4683))
          (4684 (cl:go pc-4684))
          (4685 (cl:go pc-4685))
          (4686 (cl:go pc-4686))
          (4687 (cl:go pc-4687))
          (4688 (cl:go pc-4688))
          (4689 (cl:go pc-4689))
          (4690 (cl:go pc-4690))
          (4691 (cl:go pc-4691))
          (4692 (cl:go pc-4692))
          (4693 (cl:go pc-4693))
          (4694 (cl:go pc-4694))
          (4695 (cl:go pc-4695))
          (4696 (cl:go pc-4696))
          (4697 (cl:go pc-4697))
          (4698 (cl:go pc-4698))
          (4699 (cl:go pc-4699))
          (4700 (cl:go pc-4700))
          (4701 (cl:go pc-4701))
          (4702 (cl:go pc-4702))
          (4703 (cl:go pc-4703))
          (4704 (cl:go pc-4704))
          (4705 (cl:go pc-4705))
          (4706 (cl:go pc-4706))
          (4707 (cl:go pc-4707))
          (4708 (cl:go pc-4708))
          (4709 (cl:go pc-4709))
          (4710 (cl:go pc-4710))
          (4711 (cl:go pc-4711))
          (4712 (cl:go pc-4712))
          (4713 (cl:go pc-4713))
          (4714 (cl:go pc-4714))
          (4715 (cl:go pc-4715))
          (4716 (cl:go pc-4716))
          (4717 (cl:go pc-4717))
          (4718 (cl:go pc-4718))
          (4719 (cl:go pc-4719))
          (4720 (cl:go pc-4720))
          (4721 (cl:go pc-4721))
          (4722 (cl:go pc-4722))
          (4723 (cl:go pc-4723))
          (4724 (cl:go pc-4724))
          (4725 (cl:go pc-4725))
          (4726 (cl:go pc-4726))
          (4727 (cl:go pc-4727))
          (4728 (cl:go pc-4728))
          (4729 (cl:go pc-4729))
          (4730 (cl:go pc-4730))
          (4731 (cl:go pc-4731))
          (4732 (cl:go pc-4732))
          (4733 (cl:go pc-4733))
          (4734 (cl:go pc-4734))
          (4735 (cl:go pc-4735))
          (4736 (cl:go pc-4736))
          (4737 (cl:go pc-4737))
          (4738 (cl:go pc-4738))
          (4739 (cl:go pc-4739))
          (4740 (cl:go pc-4740))
          (4741 (cl:go pc-4741))
          (4742 (cl:go pc-4742))
          (4743 (cl:go pc-4743))
          (4744 (cl:go pc-4744))
          (4745 (cl:go pc-4745))
          (4746 (cl:go pc-4746))
          (4747 (cl:go pc-4747))
          (4748 (cl:go pc-4748))
          (4749 (cl:go pc-4749))
          (4750 (cl:go pc-4750))
          (4751 (cl:go pc-4751))
          (4752 (cl:go pc-4752))
          (4753 (cl:go pc-4753))
          (4754 (cl:go pc-4754))
          (4755 (cl:go pc-4755))
          (4756 (cl:go pc-4756))
          (4757 (cl:go pc-4757))
          (4758 (cl:go pc-4758))
          (4759 (cl:go pc-4759))
          (4760 (cl:go pc-4760))
          (4761 (cl:go pc-4761))
          (4762 (cl:go pc-4762))
          (4763 (cl:go pc-4763))
          (4764 (cl:go pc-4764))
          (4765 (cl:go pc-4765))
          (4766 (cl:go pc-4766))
          (4767 (cl:go pc-4767))
          (4768 (cl:go pc-4768))
          (4769 (cl:go pc-4769))
          (4770 (cl:go pc-4770))
          (4771 (cl:go pc-4771))
          (4772 (cl:go pc-4772))
          (4773 (cl:go pc-4773))
          (4774 (cl:go pc-4774))
          (4775 (cl:go pc-4775))
          (4776 (cl:go pc-4776))
          (4777 (cl:go pc-4777))
          (4778 (cl:go pc-4778))
          (4779 (cl:go pc-4779))
          (4780 (cl:go pc-4780))
          (4781 (cl:go pc-4781))
          (4782 (cl:go pc-4782))
          (4783 (cl:go pc-4783))
          (4784 (cl:go pc-4784))
          (4785 (cl:go pc-4785))
          (4786 (cl:go pc-4786))
          (4787 (cl:go pc-4787))
          (4788 (cl:go pc-4788))
          (4789 (cl:go pc-4789))
          (4790 (cl:go pc-4790))
          (4791 (cl:go pc-4791))
          (4792 (cl:go pc-4792))
          (4793 (cl:go pc-4793))
          (4794 (cl:go pc-4794))
          (4795 (cl:go pc-4795))
          (4796 (cl:go pc-4796))
          (4797 (cl:go pc-4797))
          (4798 (cl:go pc-4798))
          (4799 (cl:go pc-4799))
          (4800 (cl:go pc-4800))
          (4801 (cl:go pc-4801))
          (4802 (cl:go pc-4802))
          (4803 (cl:go pc-4803))
          (4804 (cl:go pc-4804))
          (4805 (cl:go pc-4805))
          (4806 (cl:go pc-4806))
          (4807 (cl:go pc-4807))
          (4808 (cl:go pc-4808))
          (4809 (cl:go pc-4809))
          (4810 (cl:go pc-4810))
          (4811 (cl:go pc-4811))
          (4812 (cl:go pc-4812))
          (4813 (cl:go pc-4813))
          (4814 (cl:go pc-4814))
          (4815 (cl:go pc-4815))
          (4816 (cl:go pc-4816))
          (4817 (cl:go pc-4817))
          (4818 (cl:go pc-4818))
          (4819 (cl:go pc-4819))
          (4820 (cl:go pc-4820))
          (4821 (cl:go pc-4821))
          (4822 (cl:go pc-4822))
          (4823 (cl:go pc-4823))
          (4824 (cl:go pc-4824))
          (4825 (cl:go pc-4825))
          (4826 (cl:go pc-4826))
          (4827 (cl:go pc-4827))
          (4828 (cl:go pc-4828))
          (4829 (cl:go pc-4829))
          (4830 (cl:go pc-4830))
          (4831 (cl:go pc-4831))
          (4832 (cl:go pc-4832))
          (4833 (cl:go pc-4833))
          (4834 (cl:go pc-4834))
          (4835 (cl:go pc-4835))
          (4836 (cl:go pc-4836))
          (4837 (cl:go pc-4837))
          (4838 (cl:go pc-4838))
          (4839 (cl:go pc-4839))
          (4840 (cl:go pc-4840))
          (4841 (cl:go pc-4841))
          (4842 (cl:go pc-4842))
          (4843 (cl:go pc-4843))
          (4844 (cl:go pc-4844))
          (4845 (cl:go pc-4845))
          (4846 (cl:go pc-4846))
          (4847 (cl:go pc-4847))
          (4848 (cl:go pc-4848))
          (4849 (cl:go pc-4849))
          (4850 (cl:go pc-4850))
          (4851 (cl:go pc-4851))
          (4852 (cl:go pc-4852))
          (4853 (cl:go pc-4853))
          (4854 (cl:go pc-4854))
          (4855 (cl:go pc-4855))
          (4856 (cl:go pc-4856))
          (4857 (cl:go pc-4857))
          (4858 (cl:go pc-4858))
          (4859 (cl:go pc-4859))
          (4860 (cl:go pc-4860))
          (4861 (cl:go pc-4861))
          (4862 (cl:go pc-4862))
          (4863 (cl:go pc-4863))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 5120)
        (cl:case pc
          (4864 (cl:go pc-4864))
          (4865 (cl:go pc-4865))
          (4866 (cl:go pc-4866))
          (4867 (cl:go pc-4867))
          (4868 (cl:go pc-4868))
          (4869 (cl:go pc-4869))
          (4870 (cl:go pc-4870))
          (4871 (cl:go pc-4871))
          (4872 (cl:go pc-4872))
          (4873 (cl:go pc-4873))
          (4874 (cl:go pc-4874))
          (4875 (cl:go pc-4875))
          (4876 (cl:go pc-4876))
          (4877 (cl:go pc-4877))
          (4878 (cl:go pc-4878))
          (4879 (cl:go pc-4879))
          (4880 (cl:go pc-4880))
          (4881 (cl:go pc-4881))
          (4882 (cl:go pc-4882))
          (4883 (cl:go pc-4883))
          (4884 (cl:go pc-4884))
          (4885 (cl:go pc-4885))
          (4886 (cl:go pc-4886))
          (4887 (cl:go pc-4887))
          (4888 (cl:go pc-4888))
          (4889 (cl:go pc-4889))
          (4890 (cl:go pc-4890))
          (4891 (cl:go pc-4891))
          (4892 (cl:go pc-4892))
          (4893 (cl:go pc-4893))
          (4894 (cl:go pc-4894))
          (4895 (cl:go pc-4895))
          (4896 (cl:go pc-4896))
          (4897 (cl:go pc-4897))
          (4898 (cl:go pc-4898))
          (4899 (cl:go pc-4899))
          (4900 (cl:go pc-4900))
          (4901 (cl:go pc-4901))
          (4902 (cl:go pc-4902))
          (4903 (cl:go pc-4903))
          (4904 (cl:go pc-4904))
          (4905 (cl:go pc-4905))
          (4906 (cl:go pc-4906))
          (4907 (cl:go pc-4907))
          (4908 (cl:go pc-4908))
          (4909 (cl:go pc-4909))
          (4910 (cl:go pc-4910))
          (4911 (cl:go pc-4911))
          (4912 (cl:go pc-4912))
          (4913 (cl:go pc-4913))
          (4914 (cl:go pc-4914))
          (4915 (cl:go pc-4915))
          (4916 (cl:go pc-4916))
          (4917 (cl:go pc-4917))
          (4918 (cl:go pc-4918))
          (4919 (cl:go pc-4919))
          (4920 (cl:go pc-4920))
          (4921 (cl:go pc-4921))
          (4922 (cl:go pc-4922))
          (4923 (cl:go pc-4923))
          (4924 (cl:go pc-4924))
          (4925 (cl:go pc-4925))
          (4926 (cl:go pc-4926))
          (4927 (cl:go pc-4927))
          (4928 (cl:go pc-4928))
          (4929 (cl:go pc-4929))
          (4930 (cl:go pc-4930))
          (4931 (cl:go pc-4931))
          (4932 (cl:go pc-4932))
          (4933 (cl:go pc-4933))
          (4934 (cl:go pc-4934))
          (4935 (cl:go pc-4935))
          (4936 (cl:go pc-4936))
          (4937 (cl:go pc-4937))
          (4938 (cl:go pc-4938))
          (4939 (cl:go pc-4939))
          (4940 (cl:go pc-4940))
          (4941 (cl:go pc-4941))
          (4942 (cl:go pc-4942))
          (4943 (cl:go pc-4943))
          (4944 (cl:go pc-4944))
          (4945 (cl:go pc-4945))
          (4946 (cl:go pc-4946))
          (4947 (cl:go pc-4947))
          (4948 (cl:go pc-4948))
          (4949 (cl:go pc-4949))
          (4950 (cl:go pc-4950))
          (4951 (cl:go pc-4951))
          (4952 (cl:go pc-4952))
          (4953 (cl:go pc-4953))
          (4954 (cl:go pc-4954))
          (4955 (cl:go pc-4955))
          (4956 (cl:go pc-4956))
          (4957 (cl:go pc-4957))
          (4958 (cl:go pc-4958))
          (4959 (cl:go pc-4959))
          (4960 (cl:go pc-4960))
          (4961 (cl:go pc-4961))
          (4962 (cl:go pc-4962))
          (4963 (cl:go pc-4963))
          (4964 (cl:go pc-4964))
          (4965 (cl:go pc-4965))
          (4966 (cl:go pc-4966))
          (4967 (cl:go pc-4967))
          (4968 (cl:go pc-4968))
          (4969 (cl:go pc-4969))
          (4970 (cl:go pc-4970))
          (4971 (cl:go pc-4971))
          (4972 (cl:go pc-4972))
          (4973 (cl:go pc-4973))
          (4974 (cl:go pc-4974))
          (4975 (cl:go pc-4975))
          (4976 (cl:go pc-4976))
          (4977 (cl:go pc-4977))
          (4978 (cl:go pc-4978))
          (4979 (cl:go pc-4979))
          (4980 (cl:go pc-4980))
          (4981 (cl:go pc-4981))
          (4982 (cl:go pc-4982))
          (4983 (cl:go pc-4983))
          (4984 (cl:go pc-4984))
          (4985 (cl:go pc-4985))
          (4986 (cl:go pc-4986))
          (4987 (cl:go pc-4987))
          (4988 (cl:go pc-4988))
          (4989 (cl:go pc-4989))
          (4990 (cl:go pc-4990))
          (4991 (cl:go pc-4991))
          (4992 (cl:go pc-4992))
          (4993 (cl:go pc-4993))
          (4994 (cl:go pc-4994))
          (4995 (cl:go pc-4995))
          (4996 (cl:go pc-4996))
          (4997 (cl:go pc-4997))
          (4998 (cl:go pc-4998))
          (4999 (cl:go pc-4999))
          (5000 (cl:go pc-5000))
          (5001 (cl:go pc-5001))
          (5002 (cl:go pc-5002))
          (5003 (cl:go pc-5003))
          (5004 (cl:go pc-5004))
          (5005 (cl:go pc-5005))
          (5006 (cl:go pc-5006))
          (5007 (cl:go pc-5007))
          (5008 (cl:go pc-5008))
          (5009 (cl:go pc-5009))
          (5010 (cl:go pc-5010))
          (5011 (cl:go pc-5011))
          (5012 (cl:go pc-5012))
          (5013 (cl:go pc-5013))
          (5014 (cl:go pc-5014))
          (5015 (cl:go pc-5015))
          (5016 (cl:go pc-5016))
          (5017 (cl:go pc-5017))
          (5018 (cl:go pc-5018))
          (5019 (cl:go pc-5019))
          (5020 (cl:go pc-5020))
          (5021 (cl:go pc-5021))
          (5022 (cl:go pc-5022))
          (5023 (cl:go pc-5023))
          (5024 (cl:go pc-5024))
          (5025 (cl:go pc-5025))
          (5026 (cl:go pc-5026))
          (5027 (cl:go pc-5027))
          (5028 (cl:go pc-5028))
          (5029 (cl:go pc-5029))
          (5030 (cl:go pc-5030))
          (5031 (cl:go pc-5031))
          (5032 (cl:go pc-5032))
          (5033 (cl:go pc-5033))
          (5034 (cl:go pc-5034))
          (5035 (cl:go pc-5035))
          (5036 (cl:go pc-5036))
          (5037 (cl:go pc-5037))
          (5038 (cl:go pc-5038))
          (5039 (cl:go pc-5039))
          (5040 (cl:go pc-5040))
          (5041 (cl:go pc-5041))
          (5042 (cl:go pc-5042))
          (5043 (cl:go pc-5043))
          (5044 (cl:go pc-5044))
          (5045 (cl:go pc-5045))
          (5046 (cl:go pc-5046))
          (5047 (cl:go pc-5047))
          (5048 (cl:go pc-5048))
          (5049 (cl:go pc-5049))
          (5050 (cl:go pc-5050))
          (5051 (cl:go pc-5051))
          (5052 (cl:go pc-5052))
          (5053 (cl:go pc-5053))
          (5054 (cl:go pc-5054))
          (5055 (cl:go pc-5055))
          (5056 (cl:go pc-5056))
          (5057 (cl:go pc-5057))
          (5058 (cl:go pc-5058))
          (5059 (cl:go pc-5059))
          (5060 (cl:go pc-5060))
          (5061 (cl:go pc-5061))
          (5062 (cl:go pc-5062))
          (5063 (cl:go pc-5063))
          (5064 (cl:go pc-5064))
          (5065 (cl:go pc-5065))
          (5066 (cl:go pc-5066))
          (5067 (cl:go pc-5067))
          (5068 (cl:go pc-5068))
          (5069 (cl:go pc-5069))
          (5070 (cl:go pc-5070))
          (5071 (cl:go pc-5071))
          (5072 (cl:go pc-5072))
          (5073 (cl:go pc-5073))
          (5074 (cl:go pc-5074))
          (5075 (cl:go pc-5075))
          (5076 (cl:go pc-5076))
          (5077 (cl:go pc-5077))
          (5078 (cl:go pc-5078))
          (5079 (cl:go pc-5079))
          (5080 (cl:go pc-5080))
          (5081 (cl:go pc-5081))
          (5082 (cl:go pc-5082))
          (5083 (cl:go pc-5083))
          (5084 (cl:go pc-5084))
          (5085 (cl:go pc-5085))
          (5086 (cl:go pc-5086))
          (5087 (cl:go pc-5087))
          (5088 (cl:go pc-5088))
          (5089 (cl:go pc-5089))
          (5090 (cl:go pc-5090))
          (5091 (cl:go pc-5091))
          (5092 (cl:go pc-5092))
          (5093 (cl:go pc-5093))
          (5094 (cl:go pc-5094))
          (5095 (cl:go pc-5095))
          (5096 (cl:go pc-5096))
          (5097 (cl:go pc-5097))
          (5098 (cl:go pc-5098))
          (5099 (cl:go pc-5099))
          (5100 (cl:go pc-5100))
          (5101 (cl:go pc-5101))
          (5102 (cl:go pc-5102))
          (5103 (cl:go pc-5103))
          (5104 (cl:go pc-5104))
          (5105 (cl:go pc-5105))
          (5106 (cl:go pc-5106))
          (5107 (cl:go pc-5107))
          (5108 (cl:go pc-5108))
          (5109 (cl:go pc-5109))
          (5110 (cl:go pc-5110))
          (5111 (cl:go pc-5111))
          (5112 (cl:go pc-5112))
          (5113 (cl:go pc-5113))
          (5114 (cl:go pc-5114))
          (5115 (cl:go pc-5115))
          (5116 (cl:go pc-5116))
          (5117 (cl:go pc-5117))
          (5118 (cl:go pc-5118))
          (5119 (cl:go pc-5119))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 5376)
        (cl:case pc
          (5120 (cl:go pc-5120))
          (5121 (cl:go pc-5121))
          (5122 (cl:go pc-5122))
          (5123 (cl:go pc-5123))
          (5124 (cl:go pc-5124))
          (5125 (cl:go pc-5125))
          (5126 (cl:go pc-5126))
          (5127 (cl:go pc-5127))
          (5128 (cl:go pc-5128))
          (5129 (cl:go pc-5129))
          (5130 (cl:go pc-5130))
          (5131 (cl:go pc-5131))
          (5132 (cl:go pc-5132))
          (5133 (cl:go pc-5133))
          (5134 (cl:go pc-5134))
          (5135 (cl:go pc-5135))
          (5136 (cl:go pc-5136))
          (5137 (cl:go pc-5137))
          (5138 (cl:go pc-5138))
          (5139 (cl:go pc-5139))
          (5140 (cl:go pc-5140))
          (5141 (cl:go pc-5141))
          (5142 (cl:go pc-5142))
          (5143 (cl:go pc-5143))
          (5144 (cl:go pc-5144))
          (5145 (cl:go pc-5145))
          (5146 (cl:go pc-5146))
          (5147 (cl:go pc-5147))
          (5148 (cl:go pc-5148))
          (5149 (cl:go pc-5149))
          (5150 (cl:go pc-5150))
          (5151 (cl:go pc-5151))
          (5152 (cl:go pc-5152))
          (5153 (cl:go pc-5153))
          (5154 (cl:go pc-5154))
          (5155 (cl:go pc-5155))
          (5156 (cl:go pc-5156))
          (5157 (cl:go pc-5157))
          (5158 (cl:go pc-5158))
          (5159 (cl:go pc-5159))
          (5160 (cl:go pc-5160))
          (5161 (cl:go pc-5161))
          (5162 (cl:go pc-5162))
          (5163 (cl:go pc-5163))
          (5164 (cl:go pc-5164))
          (5165 (cl:go pc-5165))
          (5166 (cl:go pc-5166))
          (5167 (cl:go pc-5167))
          (5168 (cl:go pc-5168))
          (5169 (cl:go pc-5169))
          (5170 (cl:go pc-5170))
          (5171 (cl:go pc-5171))
          (5172 (cl:go pc-5172))
          (5173 (cl:go pc-5173))
          (5174 (cl:go pc-5174))
          (5175 (cl:go pc-5175))
          (5176 (cl:go pc-5176))
          (5177 (cl:go pc-5177))
          (5178 (cl:go pc-5178))
          (5179 (cl:go pc-5179))
          (5180 (cl:go pc-5180))
          (5181 (cl:go pc-5181))
          (5182 (cl:go pc-5182))
          (5183 (cl:go pc-5183))
          (5184 (cl:go pc-5184))
          (5185 (cl:go pc-5185))
          (5186 (cl:go pc-5186))
          (5187 (cl:go pc-5187))
          (5188 (cl:go pc-5188))
          (5189 (cl:go pc-5189))
          (5190 (cl:go pc-5190))
          (5191 (cl:go pc-5191))
          (5192 (cl:go pc-5192))
          (5193 (cl:go pc-5193))
          (5194 (cl:go pc-5194))
          (5195 (cl:go pc-5195))
          (5196 (cl:go pc-5196))
          (5197 (cl:go pc-5197))
          (5198 (cl:go pc-5198))
          (5199 (cl:go pc-5199))
          (5200 (cl:go pc-5200))
          (5201 (cl:go pc-5201))
          (5202 (cl:go pc-5202))
          (5203 (cl:go pc-5203))
          (5204 (cl:go pc-5204))
          (5205 (cl:go pc-5205))
          (5206 (cl:go pc-5206))
          (5207 (cl:go pc-5207))
          (5208 (cl:go pc-5208))
          (5209 (cl:go pc-5209))
          (5210 (cl:go pc-5210))
          (5211 (cl:go pc-5211))
          (5212 (cl:go pc-5212))
          (5213 (cl:go pc-5213))
          (5214 (cl:go pc-5214))
          (5215 (cl:go pc-5215))
          (5216 (cl:go pc-5216))
          (5217 (cl:go pc-5217))
          (5218 (cl:go pc-5218))
          (5219 (cl:go pc-5219))
          (5220 (cl:go pc-5220))
          (5221 (cl:go pc-5221))
          (5222 (cl:go pc-5222))
          (5223 (cl:go pc-5223))
          (5224 (cl:go pc-5224))
          (5225 (cl:go pc-5225))
          (5226 (cl:go pc-5226))
          (5227 (cl:go pc-5227))
          (5228 (cl:go pc-5228))
          (5229 (cl:go pc-5229))
          (5230 (cl:go pc-5230))
          (5231 (cl:go pc-5231))
          (5232 (cl:go pc-5232))
          (5233 (cl:go pc-5233))
          (5234 (cl:go pc-5234))
          (5235 (cl:go pc-5235))
          (5236 (cl:go pc-5236))
          (5237 (cl:go pc-5237))
          (5238 (cl:go pc-5238))
          (5239 (cl:go pc-5239))
          (5240 (cl:go pc-5240))
          (5241 (cl:go pc-5241))
          (5242 (cl:go pc-5242))
          (5243 (cl:go pc-5243))
          (5244 (cl:go pc-5244))
          (5245 (cl:go pc-5245))
          (5246 (cl:go pc-5246))
          (5247 (cl:go pc-5247))
          (5248 (cl:go pc-5248))
          (5249 (cl:go pc-5249))
          (5250 (cl:go pc-5250))
          (5251 (cl:go pc-5251))
          (5252 (cl:go pc-5252))
          (5253 (cl:go pc-5253))
          (5254 (cl:go pc-5254))
          (5255 (cl:go pc-5255))
          (5256 (cl:go pc-5256))
          (5257 (cl:go pc-5257))
          (5258 (cl:go pc-5258))
          (5259 (cl:go pc-5259))
          (5260 (cl:go pc-5260))
          (5261 (cl:go pc-5261))
          (5262 (cl:go pc-5262))
          (5263 (cl:go pc-5263))
          (5264 (cl:go pc-5264))
          (5265 (cl:go pc-5265))
          (5266 (cl:go pc-5266))
          (5267 (cl:go pc-5267))
          (5268 (cl:go pc-5268))
          (5269 (cl:go pc-5269))
          (5270 (cl:go pc-5270))
          (5271 (cl:go pc-5271))
          (5272 (cl:go pc-5272))
          (5273 (cl:go pc-5273))
          (5274 (cl:go pc-5274))
          (5275 (cl:go pc-5275))
          (5276 (cl:go pc-5276))
          (5277 (cl:go pc-5277))
          (5278 (cl:go pc-5278))
          (5279 (cl:go pc-5279))
          (5280 (cl:go pc-5280))
          (5281 (cl:go pc-5281))
          (5282 (cl:go pc-5282))
          (5283 (cl:go pc-5283))
          (5284 (cl:go pc-5284))
          (5285 (cl:go pc-5285))
          (5286 (cl:go pc-5286))
          (5287 (cl:go pc-5287))
          (5288 (cl:go pc-5288))
          (5289 (cl:go pc-5289))
          (5290 (cl:go pc-5290))
          (5291 (cl:go pc-5291))
          (5292 (cl:go pc-5292))
          (5293 (cl:go pc-5293))
          (5294 (cl:go pc-5294))
          (5295 (cl:go pc-5295))
          (5296 (cl:go pc-5296))
          (5297 (cl:go pc-5297))
          (5298 (cl:go pc-5298))
          (5299 (cl:go pc-5299))
          (5300 (cl:go pc-5300))
          (5301 (cl:go pc-5301))
          (5302 (cl:go pc-5302))
          (5303 (cl:go pc-5303))
          (5304 (cl:go pc-5304))
          (5305 (cl:go pc-5305))
          (5306 (cl:go pc-5306))
          (5307 (cl:go pc-5307))
          (5308 (cl:go pc-5308))
          (5309 (cl:go pc-5309))
          (5310 (cl:go pc-5310))
          (5311 (cl:go pc-5311))
          (5312 (cl:go pc-5312))
          (5313 (cl:go pc-5313))
          (5314 (cl:go pc-5314))
          (5315 (cl:go pc-5315))
          (5316 (cl:go pc-5316))
          (5317 (cl:go pc-5317))
          (5318 (cl:go pc-5318))
          (5319 (cl:go pc-5319))
          (5320 (cl:go pc-5320))
          (5321 (cl:go pc-5321))
          (5322 (cl:go pc-5322))
          (5323 (cl:go pc-5323))
          (5324 (cl:go pc-5324))
          (5325 (cl:go pc-5325))
          (5326 (cl:go pc-5326))
          (5327 (cl:go pc-5327))
          (5328 (cl:go pc-5328))
          (5329 (cl:go pc-5329))
          (5330 (cl:go pc-5330))
          (5331 (cl:go pc-5331))
          (5332 (cl:go pc-5332))
          (5333 (cl:go pc-5333))
          (5334 (cl:go pc-5334))
          (5335 (cl:go pc-5335))
          (5336 (cl:go pc-5336))
          (5337 (cl:go pc-5337))
          (5338 (cl:go pc-5338))
          (5339 (cl:go pc-5339))
          (5340 (cl:go pc-5340))
          (5341 (cl:go pc-5341))
          (5342 (cl:go pc-5342))
          (5343 (cl:go pc-5343))
          (5344 (cl:go pc-5344))
          (5345 (cl:go pc-5345))
          (5346 (cl:go pc-5346))
          (5347 (cl:go pc-5347))
          (5348 (cl:go pc-5348))
          (5349 (cl:go pc-5349))
          (5350 (cl:go pc-5350))
          (5351 (cl:go pc-5351))
          (5352 (cl:go pc-5352))
          (5353 (cl:go pc-5353))
          (5354 (cl:go pc-5354))
          (5355 (cl:go pc-5355))
          (5356 (cl:go pc-5356))
          (5357 (cl:go pc-5357))
          (5358 (cl:go pc-5358))
          (5359 (cl:go pc-5359))
          (5360 (cl:go pc-5360))
          (5361 (cl:go pc-5361))
          (5362 (cl:go pc-5362))
          (5363 (cl:go pc-5363))
          (5364 (cl:go pc-5364))
          (5365 (cl:go pc-5365))
          (5366 (cl:go pc-5366))
          (5367 (cl:go pc-5367))
          (5368 (cl:go pc-5368))
          (5369 (cl:go pc-5369))
          (5370 (cl:go pc-5370))
          (5371 (cl:go pc-5371))
          (5372 (cl:go pc-5372))
          (5373 (cl:go pc-5373))
          (5374 (cl:go pc-5374))
          (5375 (cl:go pc-5375))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 5632)
        (cl:case pc
          (5376 (cl:go pc-5376))
          (5377 (cl:go pc-5377))
          (5378 (cl:go pc-5378))
          (5379 (cl:go pc-5379))
          (5380 (cl:go pc-5380))
          (5381 (cl:go pc-5381))
          (5382 (cl:go pc-5382))
          (5383 (cl:go pc-5383))
          (5384 (cl:go pc-5384))
          (5385 (cl:go pc-5385))
          (5386 (cl:go pc-5386))
          (5387 (cl:go pc-5387))
          (5388 (cl:go pc-5388))
          (5389 (cl:go pc-5389))
          (5390 (cl:go pc-5390))
          (5391 (cl:go pc-5391))
          (5392 (cl:go pc-5392))
          (5393 (cl:go pc-5393))
          (5394 (cl:go pc-5394))
          (5395 (cl:go pc-5395))
          (5396 (cl:go pc-5396))
          (5397 (cl:go pc-5397))
          (5398 (cl:go pc-5398))
          (5399 (cl:go pc-5399))
          (5400 (cl:go pc-5400))
          (5401 (cl:go pc-5401))
          (5402 (cl:go pc-5402))
          (5403 (cl:go pc-5403))
          (5404 (cl:go pc-5404))
          (5405 (cl:go pc-5405))
          (5406 (cl:go pc-5406))
          (5407 (cl:go pc-5407))
          (5408 (cl:go pc-5408))
          (5409 (cl:go pc-5409))
          (5410 (cl:go pc-5410))
          (5411 (cl:go pc-5411))
          (5412 (cl:go pc-5412))
          (5413 (cl:go pc-5413))
          (5414 (cl:go pc-5414))
          (5415 (cl:go pc-5415))
          (5416 (cl:go pc-5416))
          (5417 (cl:go pc-5417))
          (5418 (cl:go pc-5418))
          (5419 (cl:go pc-5419))
          (5420 (cl:go pc-5420))
          (5421 (cl:go pc-5421))
          (5422 (cl:go pc-5422))
          (5423 (cl:go pc-5423))
          (5424 (cl:go pc-5424))
          (5425 (cl:go pc-5425))
          (5426 (cl:go pc-5426))
          (5427 (cl:go pc-5427))
          (5428 (cl:go pc-5428))
          (5429 (cl:go pc-5429))
          (5430 (cl:go pc-5430))
          (5431 (cl:go pc-5431))
          (5432 (cl:go pc-5432))
          (5433 (cl:go pc-5433))
          (5434 (cl:go pc-5434))
          (5435 (cl:go pc-5435))
          (5436 (cl:go pc-5436))
          (5437 (cl:go pc-5437))
          (5438 (cl:go pc-5438))
          (5439 (cl:go pc-5439))
          (5440 (cl:go pc-5440))
          (5441 (cl:go pc-5441))
          (5442 (cl:go pc-5442))
          (5443 (cl:go pc-5443))
          (5444 (cl:go pc-5444))
          (5445 (cl:go pc-5445))
          (5446 (cl:go pc-5446))
          (5447 (cl:go pc-5447))
          (5448 (cl:go pc-5448))
          (5449 (cl:go pc-5449))
          (5450 (cl:go pc-5450))
          (5451 (cl:go pc-5451))
          (5452 (cl:go pc-5452))
          (5453 (cl:go pc-5453))
          (5454 (cl:go pc-5454))
          (5455 (cl:go pc-5455))
          (5456 (cl:go pc-5456))
          (5457 (cl:go pc-5457))
          (5458 (cl:go pc-5458))
          (5459 (cl:go pc-5459))
          (5460 (cl:go pc-5460))
          (5461 (cl:go pc-5461))
          (5462 (cl:go pc-5462))
          (5463 (cl:go pc-5463))
          (5464 (cl:go pc-5464))
          (5465 (cl:go pc-5465))
          (5466 (cl:go pc-5466))
          (5467 (cl:go pc-5467))
          (5468 (cl:go pc-5468))
          (5469 (cl:go pc-5469))
          (5470 (cl:go pc-5470))
          (5471 (cl:go pc-5471))
          (5472 (cl:go pc-5472))
          (5473 (cl:go pc-5473))
          (5474 (cl:go pc-5474))
          (5475 (cl:go pc-5475))
          (5476 (cl:go pc-5476))
          (5477 (cl:go pc-5477))
          (5478 (cl:go pc-5478))
          (5479 (cl:go pc-5479))
          (5480 (cl:go pc-5480))
          (5481 (cl:go pc-5481))
          (5482 (cl:go pc-5482))
          (5483 (cl:go pc-5483))
          (5484 (cl:go pc-5484))
          (5485 (cl:go pc-5485))
          (5486 (cl:go pc-5486))
          (5487 (cl:go pc-5487))
          (5488 (cl:go pc-5488))
          (5489 (cl:go pc-5489))
          (5490 (cl:go pc-5490))
          (5491 (cl:go pc-5491))
          (5492 (cl:go pc-5492))
          (5493 (cl:go pc-5493))
          (5494 (cl:go pc-5494))
          (5495 (cl:go pc-5495))
          (5496 (cl:go pc-5496))
          (5497 (cl:go pc-5497))
          (5498 (cl:go pc-5498))
          (5499 (cl:go pc-5499))
          (5500 (cl:go pc-5500))
          (5501 (cl:go pc-5501))
          (5502 (cl:go pc-5502))
          (5503 (cl:go pc-5503))
          (5504 (cl:go pc-5504))
          (5505 (cl:go pc-5505))
          (5506 (cl:go pc-5506))
          (5507 (cl:go pc-5507))
          (5508 (cl:go pc-5508))
          (5509 (cl:go pc-5509))
          (5510 (cl:go pc-5510))
          (5511 (cl:go pc-5511))
          (5512 (cl:go pc-5512))
          (5513 (cl:go pc-5513))
          (5514 (cl:go pc-5514))
          (5515 (cl:go pc-5515))
          (5516 (cl:go pc-5516))
          (5517 (cl:go pc-5517))
          (5518 (cl:go pc-5518))
          (5519 (cl:go pc-5519))
          (5520 (cl:go pc-5520))
          (5521 (cl:go pc-5521))
          (5522 (cl:go pc-5522))
          (5523 (cl:go pc-5523))
          (5524 (cl:go pc-5524))
          (5525 (cl:go pc-5525))
          (5526 (cl:go pc-5526))
          (5527 (cl:go pc-5527))
          (5528 (cl:go pc-5528))
          (5529 (cl:go pc-5529))
          (5530 (cl:go pc-5530))
          (5531 (cl:go pc-5531))
          (5532 (cl:go pc-5532))
          (5533 (cl:go pc-5533))
          (5534 (cl:go pc-5534))
          (5535 (cl:go pc-5535))
          (5536 (cl:go pc-5536))
          (5537 (cl:go pc-5537))
          (5538 (cl:go pc-5538))
          (5539 (cl:go pc-5539))
          (5540 (cl:go pc-5540))
          (5541 (cl:go pc-5541))
          (5542 (cl:go pc-5542))
          (5543 (cl:go pc-5543))
          (5544 (cl:go pc-5544))
          (5545 (cl:go pc-5545))
          (5546 (cl:go pc-5546))
          (5547 (cl:go pc-5547))
          (5548 (cl:go pc-5548))
          (5549 (cl:go pc-5549))
          (5550 (cl:go pc-5550))
          (5551 (cl:go pc-5551))
          (5552 (cl:go pc-5552))
          (5553 (cl:go pc-5553))
          (5554 (cl:go pc-5554))
          (5555 (cl:go pc-5555))
          (5556 (cl:go pc-5556))
          (5557 (cl:go pc-5557))
          (5558 (cl:go pc-5558))
          (5559 (cl:go pc-5559))
          (5560 (cl:go pc-5560))
          (5561 (cl:go pc-5561))
          (5562 (cl:go pc-5562))
          (5563 (cl:go pc-5563))
          (5564 (cl:go pc-5564))
          (5565 (cl:go pc-5565))
          (5566 (cl:go pc-5566))
          (5567 (cl:go pc-5567))
          (5568 (cl:go pc-5568))
          (5569 (cl:go pc-5569))
          (5570 (cl:go pc-5570))
          (5571 (cl:go pc-5571))
          (5572 (cl:go pc-5572))
          (5573 (cl:go pc-5573))
          (5574 (cl:go pc-5574))
          (5575 (cl:go pc-5575))
          (5576 (cl:go pc-5576))
          (5577 (cl:go pc-5577))
          (5578 (cl:go pc-5578))
          (5579 (cl:go pc-5579))
          (5580 (cl:go pc-5580))
          (5581 (cl:go pc-5581))
          (5582 (cl:go pc-5582))
          (5583 (cl:go pc-5583))
          (5584 (cl:go pc-5584))
          (5585 (cl:go pc-5585))
          (5586 (cl:go pc-5586))
          (5587 (cl:go pc-5587))
          (5588 (cl:go pc-5588))
          (5589 (cl:go pc-5589))
          (5590 (cl:go pc-5590))
          (5591 (cl:go pc-5591))
          (5592 (cl:go pc-5592))
          (5593 (cl:go pc-5593))
          (5594 (cl:go pc-5594))
          (5595 (cl:go pc-5595))
          (5596 (cl:go pc-5596))
          (5597 (cl:go pc-5597))
          (5598 (cl:go pc-5598))
          (5599 (cl:go pc-5599))
          (5600 (cl:go pc-5600))
          (5601 (cl:go pc-5601))
          (5602 (cl:go pc-5602))
          (5603 (cl:go pc-5603))
          (5604 (cl:go pc-5604))
          (5605 (cl:go pc-5605))
          (5606 (cl:go pc-5606))
          (5607 (cl:go pc-5607))
          (5608 (cl:go pc-5608))
          (5609 (cl:go pc-5609))
          (5610 (cl:go pc-5610))
          (5611 (cl:go pc-5611))
          (5612 (cl:go pc-5612))
          (5613 (cl:go pc-5613))
          (5614 (cl:go pc-5614))
          (5615 (cl:go pc-5615))
          (5616 (cl:go pc-5616))
          (5617 (cl:go pc-5617))
          (5618 (cl:go pc-5618))
          (5619 (cl:go pc-5619))
          (5620 (cl:go pc-5620))
          (5621 (cl:go pc-5621))
          (5622 (cl:go pc-5622))
          (5623 (cl:go pc-5623))
          (5624 (cl:go pc-5624))
          (5625 (cl:go pc-5625))
          (5626 (cl:go pc-5626))
          (5627 (cl:go pc-5627))
          (5628 (cl:go pc-5628))
          (5629 (cl:go pc-5629))
          (5630 (cl:go pc-5630))
          (5631 (cl:go pc-5631))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 5888)
        (cl:case pc
          (5632 (cl:go pc-5632))
          (5633 (cl:go pc-5633))
          (5634 (cl:go pc-5634))
          (5635 (cl:go pc-5635))
          (5636 (cl:go pc-5636))
          (5637 (cl:go pc-5637))
          (5638 (cl:go pc-5638))
          (5639 (cl:go pc-5639))
          (5640 (cl:go pc-5640))
          (5641 (cl:go pc-5641))
          (5642 (cl:go pc-5642))
          (5643 (cl:go pc-5643))
          (5644 (cl:go pc-5644))
          (5645 (cl:go pc-5645))
          (5646 (cl:go pc-5646))
          (5647 (cl:go pc-5647))
          (5648 (cl:go pc-5648))
          (5649 (cl:go pc-5649))
          (5650 (cl:go pc-5650))
          (5651 (cl:go pc-5651))
          (5652 (cl:go pc-5652))
          (5653 (cl:go pc-5653))
          (5654 (cl:go pc-5654))
          (5655 (cl:go pc-5655))
          (5656 (cl:go pc-5656))
          (5657 (cl:go pc-5657))
          (5658 (cl:go pc-5658))
          (5659 (cl:go pc-5659))
          (5660 (cl:go pc-5660))
          (5661 (cl:go pc-5661))
          (5662 (cl:go pc-5662))
          (5663 (cl:go pc-5663))
          (5664 (cl:go pc-5664))
          (5665 (cl:go pc-5665))
          (5666 (cl:go pc-5666))
          (5667 (cl:go pc-5667))
          (5668 (cl:go pc-5668))
          (5669 (cl:go pc-5669))
          (5670 (cl:go pc-5670))
          (5671 (cl:go pc-5671))
          (5672 (cl:go pc-5672))
          (5673 (cl:go pc-5673))
          (5674 (cl:go pc-5674))
          (5675 (cl:go pc-5675))
          (5676 (cl:go pc-5676))
          (5677 (cl:go pc-5677))
          (5678 (cl:go pc-5678))
          (5679 (cl:go pc-5679))
          (5680 (cl:go pc-5680))
          (5681 (cl:go pc-5681))
          (5682 (cl:go pc-5682))
          (5683 (cl:go pc-5683))
          (5684 (cl:go pc-5684))
          (5685 (cl:go pc-5685))
          (5686 (cl:go pc-5686))
          (5687 (cl:go pc-5687))
          (5688 (cl:go pc-5688))
          (5689 (cl:go pc-5689))
          (5690 (cl:go pc-5690))
          (5691 (cl:go pc-5691))
          (5692 (cl:go pc-5692))
          (5693 (cl:go pc-5693))
          (5694 (cl:go pc-5694))
          (5695 (cl:go pc-5695))
          (5696 (cl:go pc-5696))
          (5697 (cl:go pc-5697))
          (5698 (cl:go pc-5698))
          (5699 (cl:go pc-5699))
          (5700 (cl:go pc-5700))
          (5701 (cl:go pc-5701))
          (5702 (cl:go pc-5702))
          (5703 (cl:go pc-5703))
          (5704 (cl:go pc-5704))
          (5705 (cl:go pc-5705))
          (5706 (cl:go pc-5706))
          (5707 (cl:go pc-5707))
          (5708 (cl:go pc-5708))
          (5709 (cl:go pc-5709))
          (5710 (cl:go pc-5710))
          (5711 (cl:go pc-5711))
          (5712 (cl:go pc-5712))
          (5713 (cl:go pc-5713))
          (5714 (cl:go pc-5714))
          (5715 (cl:go pc-5715))
          (5716 (cl:go pc-5716))
          (5717 (cl:go pc-5717))
          (5718 (cl:go pc-5718))
          (5719 (cl:go pc-5719))
          (5720 (cl:go pc-5720))
          (5721 (cl:go pc-5721))
          (5722 (cl:go pc-5722))
          (5723 (cl:go pc-5723))
          (5724 (cl:go pc-5724))
          (5725 (cl:go pc-5725))
          (5726 (cl:go pc-5726))
          (5727 (cl:go pc-5727))
          (5728 (cl:go pc-5728))
          (5729 (cl:go pc-5729))
          (5730 (cl:go pc-5730))
          (5731 (cl:go pc-5731))
          (5732 (cl:go pc-5732))
          (5733 (cl:go pc-5733))
          (5734 (cl:go pc-5734))
          (5735 (cl:go pc-5735))
          (5736 (cl:go pc-5736))
          (5737 (cl:go pc-5737))
          (5738 (cl:go pc-5738))
          (5739 (cl:go pc-5739))
          (5740 (cl:go pc-5740))
          (5741 (cl:go pc-5741))
          (5742 (cl:go pc-5742))
          (5743 (cl:go pc-5743))
          (5744 (cl:go pc-5744))
          (5745 (cl:go pc-5745))
          (5746 (cl:go pc-5746))
          (5747 (cl:go pc-5747))
          (5748 (cl:go pc-5748))
          (5749 (cl:go pc-5749))
          (5750 (cl:go pc-5750))
          (5751 (cl:go pc-5751))
          (5752 (cl:go pc-5752))
          (5753 (cl:go pc-5753))
          (5754 (cl:go pc-5754))
          (5755 (cl:go pc-5755))
          (5756 (cl:go pc-5756))
          (5757 (cl:go pc-5757))
          (5758 (cl:go pc-5758))
          (5759 (cl:go pc-5759))
          (5760 (cl:go pc-5760))
          (5761 (cl:go pc-5761))
          (5762 (cl:go pc-5762))
          (5763 (cl:go pc-5763))
          (5764 (cl:go pc-5764))
          (5765 (cl:go pc-5765))
          (5766 (cl:go pc-5766))
          (5767 (cl:go pc-5767))
          (5768 (cl:go pc-5768))
          (5769 (cl:go pc-5769))
          (5770 (cl:go pc-5770))
          (5771 (cl:go pc-5771))
          (5772 (cl:go pc-5772))
          (5773 (cl:go pc-5773))
          (5774 (cl:go pc-5774))
          (5775 (cl:go pc-5775))
          (5776 (cl:go pc-5776))
          (5777 (cl:go pc-5777))
          (5778 (cl:go pc-5778))
          (5779 (cl:go pc-5779))
          (5780 (cl:go pc-5780))
          (5781 (cl:go pc-5781))
          (5782 (cl:go pc-5782))
          (5783 (cl:go pc-5783))
          (5784 (cl:go pc-5784))
          (5785 (cl:go pc-5785))
          (5786 (cl:go pc-5786))
          (5787 (cl:go pc-5787))
          (5788 (cl:go pc-5788))
          (5789 (cl:go pc-5789))
          (5790 (cl:go pc-5790))
          (5791 (cl:go pc-5791))
          (5792 (cl:go pc-5792))
          (5793 (cl:go pc-5793))
          (5794 (cl:go pc-5794))
          (5795 (cl:go pc-5795))
          (5796 (cl:go pc-5796))
          (5797 (cl:go pc-5797))
          (5798 (cl:go pc-5798))
          (5799 (cl:go pc-5799))
          (5800 (cl:go pc-5800))
          (5801 (cl:go pc-5801))
          (5802 (cl:go pc-5802))
          (5803 (cl:go pc-5803))
          (5804 (cl:go pc-5804))
          (5805 (cl:go pc-5805))
          (5806 (cl:go pc-5806))
          (5807 (cl:go pc-5807))
          (5808 (cl:go pc-5808))
          (5809 (cl:go pc-5809))
          (5810 (cl:go pc-5810))
          (5811 (cl:go pc-5811))
          (5812 (cl:go pc-5812))
          (5813 (cl:go pc-5813))
          (5814 (cl:go pc-5814))
          (5815 (cl:go pc-5815))
          (5816 (cl:go pc-5816))
          (5817 (cl:go pc-5817))
          (5818 (cl:go pc-5818))
          (5819 (cl:go pc-5819))
          (5820 (cl:go pc-5820))
          (5821 (cl:go pc-5821))
          (5822 (cl:go pc-5822))
          (5823 (cl:go pc-5823))
          (5824 (cl:go pc-5824))
          (5825 (cl:go pc-5825))
          (5826 (cl:go pc-5826))
          (5827 (cl:go pc-5827))
          (5828 (cl:go pc-5828))
          (5829 (cl:go pc-5829))
          (5830 (cl:go pc-5830))
          (5831 (cl:go pc-5831))
          (5832 (cl:go pc-5832))
          (5833 (cl:go pc-5833))
          (5834 (cl:go pc-5834))
          (5835 (cl:go pc-5835))
          (5836 (cl:go pc-5836))
          (5837 (cl:go pc-5837))
          (5838 (cl:go pc-5838))
          (5839 (cl:go pc-5839))
          (5840 (cl:go pc-5840))
          (5841 (cl:go pc-5841))
          (5842 (cl:go pc-5842))
          (5843 (cl:go pc-5843))
          (5844 (cl:go pc-5844))
          (5845 (cl:go pc-5845))
          (5846 (cl:go pc-5846))
          (5847 (cl:go pc-5847))
          (5848 (cl:go pc-5848))
          (5849 (cl:go pc-5849))
          (5850 (cl:go pc-5850))
          (5851 (cl:go pc-5851))
          (5852 (cl:go pc-5852))
          (5853 (cl:go pc-5853))
          (5854 (cl:go pc-5854))
          (5855 (cl:go pc-5855))
          (5856 (cl:go pc-5856))
          (5857 (cl:go pc-5857))
          (5858 (cl:go pc-5858))
          (5859 (cl:go pc-5859))
          (5860 (cl:go pc-5860))
          (5861 (cl:go pc-5861))
          (5862 (cl:go pc-5862))
          (5863 (cl:go pc-5863))
          (5864 (cl:go pc-5864))
          (5865 (cl:go pc-5865))
          (5866 (cl:go pc-5866))
          (5867 (cl:go pc-5867))
          (5868 (cl:go pc-5868))
          (5869 (cl:go pc-5869))
          (5870 (cl:go pc-5870))
          (5871 (cl:go pc-5871))
          (5872 (cl:go pc-5872))
          (5873 (cl:go pc-5873))
          (5874 (cl:go pc-5874))
          (5875 (cl:go pc-5875))
          (5876 (cl:go pc-5876))
          (5877 (cl:go pc-5877))
          (5878 (cl:go pc-5878))
          (5879 (cl:go pc-5879))
          (5880 (cl:go pc-5880))
          (5881 (cl:go pc-5881))
          (5882 (cl:go pc-5882))
          (5883 (cl:go pc-5883))
          (5884 (cl:go pc-5884))
          (5885 (cl:go pc-5885))
          (5886 (cl:go pc-5886))
          (5887 (cl:go pc-5887))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 6144)
        (cl:case pc
          (5888 (cl:go pc-5888))
          (5889 (cl:go pc-5889))
          (5890 (cl:go pc-5890))
          (5891 (cl:go pc-5891))
          (5892 (cl:go pc-5892))
          (5893 (cl:go pc-5893))
          (5894 (cl:go pc-5894))
          (5895 (cl:go pc-5895))
          (5896 (cl:go pc-5896))
          (5897 (cl:go pc-5897))
          (5898 (cl:go pc-5898))
          (5899 (cl:go pc-5899))
          (5900 (cl:go pc-5900))
          (5901 (cl:go pc-5901))
          (5902 (cl:go pc-5902))
          (5903 (cl:go pc-5903))
          (5904 (cl:go pc-5904))
          (5905 (cl:go pc-5905))
          (5906 (cl:go pc-5906))
          (5907 (cl:go pc-5907))
          (5908 (cl:go pc-5908))
          (5909 (cl:go pc-5909))
          (5910 (cl:go pc-5910))
          (5911 (cl:go pc-5911))
          (5912 (cl:go pc-5912))
          (5913 (cl:go pc-5913))
          (5914 (cl:go pc-5914))
          (5915 (cl:go pc-5915))
          (5916 (cl:go pc-5916))
          (5917 (cl:go pc-5917))
          (5918 (cl:go pc-5918))
          (5919 (cl:go pc-5919))
          (5920 (cl:go pc-5920))
          (5921 (cl:go pc-5921))
          (5922 (cl:go pc-5922))
          (5923 (cl:go pc-5923))
          (5924 (cl:go pc-5924))
          (5925 (cl:go pc-5925))
          (5926 (cl:go pc-5926))
          (5927 (cl:go pc-5927))
          (5928 (cl:go pc-5928))
          (5929 (cl:go pc-5929))
          (5930 (cl:go pc-5930))
          (5931 (cl:go pc-5931))
          (5932 (cl:go pc-5932))
          (5933 (cl:go pc-5933))
          (5934 (cl:go pc-5934))
          (5935 (cl:go pc-5935))
          (5936 (cl:go pc-5936))
          (5937 (cl:go pc-5937))
          (5938 (cl:go pc-5938))
          (5939 (cl:go pc-5939))
          (5940 (cl:go pc-5940))
          (5941 (cl:go pc-5941))
          (5942 (cl:go pc-5942))
          (5943 (cl:go pc-5943))
          (5944 (cl:go pc-5944))
          (5945 (cl:go pc-5945))
          (5946 (cl:go pc-5946))
          (5947 (cl:go pc-5947))
          (5948 (cl:go pc-5948))
          (5949 (cl:go pc-5949))
          (5950 (cl:go pc-5950))
          (5951 (cl:go pc-5951))
          (5952 (cl:go pc-5952))
          (5953 (cl:go pc-5953))
          (5954 (cl:go pc-5954))
          (5955 (cl:go pc-5955))
          (5956 (cl:go pc-5956))
          (5957 (cl:go pc-5957))
          (5958 (cl:go pc-5958))
          (5959 (cl:go pc-5959))
          (5960 (cl:go pc-5960))
          (5961 (cl:go pc-5961))
          (5962 (cl:go pc-5962))
          (5963 (cl:go pc-5963))
          (5964 (cl:go pc-5964))
          (5965 (cl:go pc-5965))
          (5966 (cl:go pc-5966))
          (5967 (cl:go pc-5967))
          (5968 (cl:go pc-5968))
          (5969 (cl:go pc-5969))
          (5970 (cl:go pc-5970))
          (5971 (cl:go pc-5971))
          (5972 (cl:go pc-5972))
          (5973 (cl:go pc-5973))
          (5974 (cl:go pc-5974))
          (5975 (cl:go pc-5975))
          (5976 (cl:go pc-5976))
          (5977 (cl:go pc-5977))
          (5978 (cl:go pc-5978))
          (5979 (cl:go pc-5979))
          (5980 (cl:go pc-5980))
          (5981 (cl:go pc-5981))
          (5982 (cl:go pc-5982))
          (5983 (cl:go pc-5983))
          (5984 (cl:go pc-5984))
          (5985 (cl:go pc-5985))
          (5986 (cl:go pc-5986))
          (5987 (cl:go pc-5987))
          (5988 (cl:go pc-5988))
          (5989 (cl:go pc-5989))
          (5990 (cl:go pc-5990))
          (5991 (cl:go pc-5991))
          (5992 (cl:go pc-5992))
          (5993 (cl:go pc-5993))
          (5994 (cl:go pc-5994))
          (5995 (cl:go pc-5995))
          (5996 (cl:go pc-5996))
          (5997 (cl:go pc-5997))
          (5998 (cl:go pc-5998))
          (5999 (cl:go pc-5999))
          (6000 (cl:go pc-6000))
          (6001 (cl:go pc-6001))
          (6002 (cl:go pc-6002))
          (6003 (cl:go pc-6003))
          (6004 (cl:go pc-6004))
          (6005 (cl:go pc-6005))
          (6006 (cl:go pc-6006))
          (6007 (cl:go pc-6007))
          (6008 (cl:go pc-6008))
          (6009 (cl:go pc-6009))
          (6010 (cl:go pc-6010))
          (6011 (cl:go pc-6011))
          (6012 (cl:go pc-6012))
          (6013 (cl:go pc-6013))
          (6014 (cl:go pc-6014))
          (6015 (cl:go pc-6015))
          (6016 (cl:go pc-6016))
          (6017 (cl:go pc-6017))
          (6018 (cl:go pc-6018))
          (6019 (cl:go pc-6019))
          (6020 (cl:go pc-6020))
          (6021 (cl:go pc-6021))
          (6022 (cl:go pc-6022))
          (6023 (cl:go pc-6023))
          (6024 (cl:go pc-6024))
          (6025 (cl:go pc-6025))
          (6026 (cl:go pc-6026))
          (6027 (cl:go pc-6027))
          (6028 (cl:go pc-6028))
          (6029 (cl:go pc-6029))
          (6030 (cl:go pc-6030))
          (6031 (cl:go pc-6031))
          (6032 (cl:go pc-6032))
          (6033 (cl:go pc-6033))
          (6034 (cl:go pc-6034))
          (6035 (cl:go pc-6035))
          (6036 (cl:go pc-6036))
          (6037 (cl:go pc-6037))
          (6038 (cl:go pc-6038))
          (6039 (cl:go pc-6039))
          (6040 (cl:go pc-6040))
          (6041 (cl:go pc-6041))
          (6042 (cl:go pc-6042))
          (6043 (cl:go pc-6043))
          (6044 (cl:go pc-6044))
          (6045 (cl:go pc-6045))
          (6046 (cl:go pc-6046))
          (6047 (cl:go pc-6047))
          (6048 (cl:go pc-6048))
          (6049 (cl:go pc-6049))
          (6050 (cl:go pc-6050))
          (6051 (cl:go pc-6051))
          (6052 (cl:go pc-6052))
          (6053 (cl:go pc-6053))
          (6054 (cl:go pc-6054))
          (6055 (cl:go pc-6055))
          (6056 (cl:go pc-6056))
          (6057 (cl:go pc-6057))
          (6058 (cl:go pc-6058))
          (6059 (cl:go pc-6059))
          (6060 (cl:go pc-6060))
          (6061 (cl:go pc-6061))
          (6062 (cl:go pc-6062))
          (6063 (cl:go pc-6063))
          (6064 (cl:go pc-6064))
          (6065 (cl:go pc-6065))
          (6066 (cl:go pc-6066))
          (6067 (cl:go pc-6067))
          (6068 (cl:go pc-6068))
          (6069 (cl:go pc-6069))
          (6070 (cl:go pc-6070))
          (6071 (cl:go pc-6071))
          (6072 (cl:go pc-6072))
          (6073 (cl:go pc-6073))
          (6074 (cl:go pc-6074))
          (6075 (cl:go pc-6075))
          (6076 (cl:go pc-6076))
          (6077 (cl:go pc-6077))
          (6078 (cl:go pc-6078))
          (6079 (cl:go pc-6079))
          (6080 (cl:go pc-6080))
          (6081 (cl:go pc-6081))
          (6082 (cl:go pc-6082))
          (6083 (cl:go pc-6083))
          (6084 (cl:go pc-6084))
          (6085 (cl:go pc-6085))
          (6086 (cl:go pc-6086))
          (6087 (cl:go pc-6087))
          (6088 (cl:go pc-6088))
          (6089 (cl:go pc-6089))
          (6090 (cl:go pc-6090))
          (6091 (cl:go pc-6091))
          (6092 (cl:go pc-6092))
          (6093 (cl:go pc-6093))
          (6094 (cl:go pc-6094))
          (6095 (cl:go pc-6095))
          (6096 (cl:go pc-6096))
          (6097 (cl:go pc-6097))
          (6098 (cl:go pc-6098))
          (6099 (cl:go pc-6099))
          (6100 (cl:go pc-6100))
          (6101 (cl:go pc-6101))
          (6102 (cl:go pc-6102))
          (6103 (cl:go pc-6103))
          (6104 (cl:go pc-6104))
          (6105 (cl:go pc-6105))
          (6106 (cl:go pc-6106))
          (6107 (cl:go pc-6107))
          (6108 (cl:go pc-6108))
          (6109 (cl:go pc-6109))
          (6110 (cl:go pc-6110))
          (6111 (cl:go pc-6111))
          (6112 (cl:go pc-6112))
          (6113 (cl:go pc-6113))
          (6114 (cl:go pc-6114))
          (6115 (cl:go pc-6115))
          (6116 (cl:go pc-6116))
          (6117 (cl:go pc-6117))
          (6118 (cl:go pc-6118))
          (6119 (cl:go pc-6119))
          (6120 (cl:go pc-6120))
          (6121 (cl:go pc-6121))
          (6122 (cl:go pc-6122))
          (6123 (cl:go pc-6123))
          (6124 (cl:go pc-6124))
          (6125 (cl:go pc-6125))
          (6126 (cl:go pc-6126))
          (6127 (cl:go pc-6127))
          (6128 (cl:go pc-6128))
          (6129 (cl:go pc-6129))
          (6130 (cl:go pc-6130))
          (6131 (cl:go pc-6131))
          (6132 (cl:go pc-6132))
          (6133 (cl:go pc-6133))
          (6134 (cl:go pc-6134))
          (6135 (cl:go pc-6135))
          (6136 (cl:go pc-6136))
          (6137 (cl:go pc-6137))
          (6138 (cl:go pc-6138))
          (6139 (cl:go pc-6139))
          (6140 (cl:go pc-6140))
          (6141 (cl:go pc-6141))
          (6142 (cl:go pc-6142))
          (6143 (cl:go pc-6143))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 6400)
        (cl:case pc
          (6144 (cl:go pc-6144))
          (6145 (cl:go pc-6145))
          (6146 (cl:go pc-6146))
          (6147 (cl:go pc-6147))
          (6148 (cl:go pc-6148))
          (6149 (cl:go pc-6149))
          (6150 (cl:go pc-6150))
          (6151 (cl:go pc-6151))
          (6152 (cl:go pc-6152))
          (6153 (cl:go pc-6153))
          (6154 (cl:go pc-6154))
          (6155 (cl:go pc-6155))
          (6156 (cl:go pc-6156))
          (6157 (cl:go pc-6157))
          (6158 (cl:go pc-6158))
          (6159 (cl:go pc-6159))
          (6160 (cl:go pc-6160))
          (6161 (cl:go pc-6161))
          (6162 (cl:go pc-6162))
          (6163 (cl:go pc-6163))
          (6164 (cl:go pc-6164))
          (6165 (cl:go pc-6165))
          (6166 (cl:go pc-6166))
          (6167 (cl:go pc-6167))
          (6168 (cl:go pc-6168))
          (6169 (cl:go pc-6169))
          (6170 (cl:go pc-6170))
          (6171 (cl:go pc-6171))
          (6172 (cl:go pc-6172))
          (6173 (cl:go pc-6173))
          (6174 (cl:go pc-6174))
          (6175 (cl:go pc-6175))
          (6176 (cl:go pc-6176))
          (6177 (cl:go pc-6177))
          (6178 (cl:go pc-6178))
          (6179 (cl:go pc-6179))
          (6180 (cl:go pc-6180))
          (6181 (cl:go pc-6181))
          (6182 (cl:go pc-6182))
          (6183 (cl:go pc-6183))
          (6184 (cl:go pc-6184))
          (6185 (cl:go pc-6185))
          (6186 (cl:go pc-6186))
          (6187 (cl:go pc-6187))
          (6188 (cl:go pc-6188))
          (6189 (cl:go pc-6189))
          (6190 (cl:go pc-6190))
          (6191 (cl:go pc-6191))
          (6192 (cl:go pc-6192))
          (6193 (cl:go pc-6193))
          (6194 (cl:go pc-6194))
          (6195 (cl:go pc-6195))
          (6196 (cl:go pc-6196))
          (6197 (cl:go pc-6197))
          (6198 (cl:go pc-6198))
          (6199 (cl:go pc-6199))
          (6200 (cl:go pc-6200))
          (6201 (cl:go pc-6201))
          (6202 (cl:go pc-6202))
          (6203 (cl:go pc-6203))
          (6204 (cl:go pc-6204))
          (6205 (cl:go pc-6205))
          (6206 (cl:go pc-6206))
          (6207 (cl:go pc-6207))
          (6208 (cl:go pc-6208))
          (6209 (cl:go pc-6209))
          (6210 (cl:go pc-6210))
          (6211 (cl:go pc-6211))
          (6212 (cl:go pc-6212))
          (6213 (cl:go pc-6213))
          (6214 (cl:go pc-6214))
          (6215 (cl:go pc-6215))
          (6216 (cl:go pc-6216))
          (6217 (cl:go pc-6217))
          (6218 (cl:go pc-6218))
          (6219 (cl:go pc-6219))
          (6220 (cl:go pc-6220))
          (6221 (cl:go pc-6221))
          (6222 (cl:go pc-6222))
          (6223 (cl:go pc-6223))
          (6224 (cl:go pc-6224))
          (6225 (cl:go pc-6225))
          (6226 (cl:go pc-6226))
          (6227 (cl:go pc-6227))
          (6228 (cl:go pc-6228))
          (6229 (cl:go pc-6229))
          (6230 (cl:go pc-6230))
          (6231 (cl:go pc-6231))
          (6232 (cl:go pc-6232))
          (6233 (cl:go pc-6233))
          (6234 (cl:go pc-6234))
          (6235 (cl:go pc-6235))
          (6236 (cl:go pc-6236))
          (6237 (cl:go pc-6237))
          (6238 (cl:go pc-6238))
          (6239 (cl:go pc-6239))
          (6240 (cl:go pc-6240))
          (6241 (cl:go pc-6241))
          (6242 (cl:go pc-6242))
          (6243 (cl:go pc-6243))
          (6244 (cl:go pc-6244))
          (6245 (cl:go pc-6245))
          (6246 (cl:go pc-6246))
          (6247 (cl:go pc-6247))
          (6248 (cl:go pc-6248))
          (6249 (cl:go pc-6249))
          (6250 (cl:go pc-6250))
          (6251 (cl:go pc-6251))
          (6252 (cl:go pc-6252))
          (6253 (cl:go pc-6253))
          (6254 (cl:go pc-6254))
          (6255 (cl:go pc-6255))
          (6256 (cl:go pc-6256))
          (6257 (cl:go pc-6257))
          (6258 (cl:go pc-6258))
          (6259 (cl:go pc-6259))
          (6260 (cl:go pc-6260))
          (6261 (cl:go pc-6261))
          (6262 (cl:go pc-6262))
          (6263 (cl:go pc-6263))
          (6264 (cl:go pc-6264))
          (6265 (cl:go pc-6265))
          (6266 (cl:go pc-6266))
          (6267 (cl:go pc-6267))
          (6268 (cl:go pc-6268))
          (6269 (cl:go pc-6269))
          (6270 (cl:go pc-6270))
          (6271 (cl:go pc-6271))
          (6272 (cl:go pc-6272))
          (6273 (cl:go pc-6273))
          (6274 (cl:go pc-6274))
          (6275 (cl:go pc-6275))
          (6276 (cl:go pc-6276))
          (6277 (cl:go pc-6277))
          (6278 (cl:go pc-6278))
          (6279 (cl:go pc-6279))
          (6280 (cl:go pc-6280))
          (6281 (cl:go pc-6281))
          (6282 (cl:go pc-6282))
          (6283 (cl:go pc-6283))
          (6284 (cl:go pc-6284))
          (6285 (cl:go pc-6285))
          (6286 (cl:go pc-6286))
          (6287 (cl:go pc-6287))
          (6288 (cl:go pc-6288))
          (6289 (cl:go pc-6289))
          (6290 (cl:go pc-6290))
          (6291 (cl:go pc-6291))
          (6292 (cl:go pc-6292))
          (6293 (cl:go pc-6293))
          (6294 (cl:go pc-6294))
          (6295 (cl:go pc-6295))
          (6296 (cl:go pc-6296))
          (6297 (cl:go pc-6297))
          (6298 (cl:go pc-6298))
          (6299 (cl:go pc-6299))
          (6300 (cl:go pc-6300))
          (6301 (cl:go pc-6301))
          (6302 (cl:go pc-6302))
          (6303 (cl:go pc-6303))
          (6304 (cl:go pc-6304))
          (6305 (cl:go pc-6305))
          (6306 (cl:go pc-6306))
          (6307 (cl:go pc-6307))
          (6308 (cl:go pc-6308))
          (6309 (cl:go pc-6309))
          (6310 (cl:go pc-6310))
          (6311 (cl:go pc-6311))
          (6312 (cl:go pc-6312))
          (6313 (cl:go pc-6313))
          (6314 (cl:go pc-6314))
          (6315 (cl:go pc-6315))
          (6316 (cl:go pc-6316))
          (6317 (cl:go pc-6317))
          (6318 (cl:go pc-6318))
          (6319 (cl:go pc-6319))
          (6320 (cl:go pc-6320))
          (6321 (cl:go pc-6321))
          (6322 (cl:go pc-6322))
          (6323 (cl:go pc-6323))
          (6324 (cl:go pc-6324))
          (6325 (cl:go pc-6325))
          (6326 (cl:go pc-6326))
          (6327 (cl:go pc-6327))
          (6328 (cl:go pc-6328))
          (6329 (cl:go pc-6329))
          (6330 (cl:go pc-6330))
          (6331 (cl:go pc-6331))
          (6332 (cl:go pc-6332))
          (6333 (cl:go pc-6333))
          (6334 (cl:go pc-6334))
          (6335 (cl:go pc-6335))
          (6336 (cl:go pc-6336))
          (6337 (cl:go pc-6337))
          (6338 (cl:go pc-6338))
          (6339 (cl:go pc-6339))
          (6340 (cl:go pc-6340))
          (6341 (cl:go pc-6341))
          (6342 (cl:go pc-6342))
          (6343 (cl:go pc-6343))
          (6344 (cl:go pc-6344))
          (6345 (cl:go pc-6345))
          (6346 (cl:go pc-6346))
          (6347 (cl:go pc-6347))
          (6348 (cl:go pc-6348))
          (6349 (cl:go pc-6349))
          (6350 (cl:go pc-6350))
          (6351 (cl:go pc-6351))
          (6352 (cl:go pc-6352))
          (6353 (cl:go pc-6353))
          (6354 (cl:go pc-6354))
          (6355 (cl:go pc-6355))
          (6356 (cl:go pc-6356))
          (6357 (cl:go pc-6357))
          (6358 (cl:go pc-6358))
          (6359 (cl:go pc-6359))
          (6360 (cl:go pc-6360))
          (6361 (cl:go pc-6361))
          (6362 (cl:go pc-6362))
          (6363 (cl:go pc-6363))
          (6364 (cl:go pc-6364))
          (6365 (cl:go pc-6365))
          (6366 (cl:go pc-6366))
          (6367 (cl:go pc-6367))
          (6368 (cl:go pc-6368))
          (6369 (cl:go pc-6369))
          (6370 (cl:go pc-6370))
          (6371 (cl:go pc-6371))
          (6372 (cl:go pc-6372))
          (6373 (cl:go pc-6373))
          (6374 (cl:go pc-6374))
          (6375 (cl:go pc-6375))
          (6376 (cl:go pc-6376))
          (6377 (cl:go pc-6377))
          (6378 (cl:go pc-6378))
          (6379 (cl:go pc-6379))
          (6380 (cl:go pc-6380))
          (6381 (cl:go pc-6381))
          (6382 (cl:go pc-6382))
          (6383 (cl:go pc-6383))
          (6384 (cl:go pc-6384))
          (6385 (cl:go pc-6385))
          (6386 (cl:go pc-6386))
          (6387 (cl:go pc-6387))
          (6388 (cl:go pc-6388))
          (6389 (cl:go pc-6389))
          (6390 (cl:go pc-6390))
          (6391 (cl:go pc-6391))
          (6392 (cl:go pc-6392))
          (6393 (cl:go pc-6393))
          (6394 (cl:go pc-6394))
          (6395 (cl:go pc-6395))
          (6396 (cl:go pc-6396))
          (6397 (cl:go pc-6397))
          (6398 (cl:go pc-6398))
          (6399 (cl:go pc-6399))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 6656)
        (cl:case pc
          (6400 (cl:go pc-6400))
          (6401 (cl:go pc-6401))
          (6402 (cl:go pc-6402))
          (6403 (cl:go pc-6403))
          (6404 (cl:go pc-6404))
          (6405 (cl:go pc-6405))
          (6406 (cl:go pc-6406))
          (6407 (cl:go pc-6407))
          (6408 (cl:go pc-6408))
          (6409 (cl:go pc-6409))
          (6410 (cl:go pc-6410))
          (6411 (cl:go pc-6411))
          (6412 (cl:go pc-6412))
          (6413 (cl:go pc-6413))
          (6414 (cl:go pc-6414))
          (6415 (cl:go pc-6415))
          (6416 (cl:go pc-6416))
          (6417 (cl:go pc-6417))
          (6418 (cl:go pc-6418))
          (6419 (cl:go pc-6419))
          (6420 (cl:go pc-6420))
          (6421 (cl:go pc-6421))
          (6422 (cl:go pc-6422))
          (6423 (cl:go pc-6423))
          (6424 (cl:go pc-6424))
          (6425 (cl:go pc-6425))
          (6426 (cl:go pc-6426))
          (6427 (cl:go pc-6427))
          (6428 (cl:go pc-6428))
          (6429 (cl:go pc-6429))
          (6430 (cl:go pc-6430))
          (6431 (cl:go pc-6431))
          (6432 (cl:go pc-6432))
          (6433 (cl:go pc-6433))
          (6434 (cl:go pc-6434))
          (6435 (cl:go pc-6435))
          (6436 (cl:go pc-6436))
          (6437 (cl:go pc-6437))
          (6438 (cl:go pc-6438))
          (6439 (cl:go pc-6439))
          (6440 (cl:go pc-6440))
          (6441 (cl:go pc-6441))
          (6442 (cl:go pc-6442))
          (6443 (cl:go pc-6443))
          (6444 (cl:go pc-6444))
          (6445 (cl:go pc-6445))
          (6446 (cl:go pc-6446))
          (6447 (cl:go pc-6447))
          (6448 (cl:go pc-6448))
          (6449 (cl:go pc-6449))
          (6450 (cl:go pc-6450))
          (6451 (cl:go pc-6451))
          (6452 (cl:go pc-6452))
          (6453 (cl:go pc-6453))
          (6454 (cl:go pc-6454))
          (6455 (cl:go pc-6455))
          (6456 (cl:go pc-6456))
          (6457 (cl:go pc-6457))
          (6458 (cl:go pc-6458))
          (6459 (cl:go pc-6459))
          (6460 (cl:go pc-6460))
          (6461 (cl:go pc-6461))
          (6462 (cl:go pc-6462))
          (6463 (cl:go pc-6463))
          (6464 (cl:go pc-6464))
          (6465 (cl:go pc-6465))
          (6466 (cl:go pc-6466))
          (6467 (cl:go pc-6467))
          (6468 (cl:go pc-6468))
          (6469 (cl:go pc-6469))
          (6470 (cl:go pc-6470))
          (6471 (cl:go pc-6471))
          (6472 (cl:go pc-6472))
          (6473 (cl:go pc-6473))
          (6474 (cl:go pc-6474))
          (6475 (cl:go pc-6475))
          (6476 (cl:go pc-6476))
          (6477 (cl:go pc-6477))
          (6478 (cl:go pc-6478))
          (6479 (cl:go pc-6479))
          (6480 (cl:go pc-6480))
          (6481 (cl:go pc-6481))
          (6482 (cl:go pc-6482))
          (6483 (cl:go pc-6483))
          (6484 (cl:go pc-6484))
          (6485 (cl:go pc-6485))
          (6486 (cl:go pc-6486))
          (6487 (cl:go pc-6487))
          (6488 (cl:go pc-6488))
          (6489 (cl:go pc-6489))
          (6490 (cl:go pc-6490))
          (6491 (cl:go pc-6491))
          (6492 (cl:go pc-6492))
          (6493 (cl:go pc-6493))
          (6494 (cl:go pc-6494))
          (6495 (cl:go pc-6495))
          (6496 (cl:go pc-6496))
          (6497 (cl:go pc-6497))
          (6498 (cl:go pc-6498))
          (6499 (cl:go pc-6499))
          (6500 (cl:go pc-6500))
          (6501 (cl:go pc-6501))
          (6502 (cl:go pc-6502))
          (6503 (cl:go pc-6503))
          (6504 (cl:go pc-6504))
          (6505 (cl:go pc-6505))
          (6506 (cl:go pc-6506))
          (6507 (cl:go pc-6507))
          (6508 (cl:go pc-6508))
          (6509 (cl:go pc-6509))
          (6510 (cl:go pc-6510))
          (6511 (cl:go pc-6511))
          (6512 (cl:go pc-6512))
          (6513 (cl:go pc-6513))
          (6514 (cl:go pc-6514))
          (6515 (cl:go pc-6515))
          (6516 (cl:go pc-6516))
          (6517 (cl:go pc-6517))
          (6518 (cl:go pc-6518))
          (6519 (cl:go pc-6519))
          (6520 (cl:go pc-6520))
          (6521 (cl:go pc-6521))
          (6522 (cl:go pc-6522))
          (6523 (cl:go pc-6523))
          (6524 (cl:go pc-6524))
          (6525 (cl:go pc-6525))
          (6526 (cl:go pc-6526))
          (6527 (cl:go pc-6527))
          (6528 (cl:go pc-6528))
          (6529 (cl:go pc-6529))
          (6530 (cl:go pc-6530))
          (6531 (cl:go pc-6531))
          (6532 (cl:go pc-6532))
          (6533 (cl:go pc-6533))
          (6534 (cl:go pc-6534))
          (6535 (cl:go pc-6535))
          (6536 (cl:go pc-6536))
          (6537 (cl:go pc-6537))
          (6538 (cl:go pc-6538))
          (6539 (cl:go pc-6539))
          (6540 (cl:go pc-6540))
          (6541 (cl:go pc-6541))
          (6542 (cl:go pc-6542))
          (6543 (cl:go pc-6543))
          (6544 (cl:go pc-6544))
          (6545 (cl:go pc-6545))
          (6546 (cl:go pc-6546))
          (6547 (cl:go pc-6547))
          (6548 (cl:go pc-6548))
          (6549 (cl:go pc-6549))
          (6550 (cl:go pc-6550))
          (6551 (cl:go pc-6551))
          (6552 (cl:go pc-6552))
          (6553 (cl:go pc-6553))
          (6554 (cl:go pc-6554))
          (6555 (cl:go pc-6555))
          (6556 (cl:go pc-6556))
          (6557 (cl:go pc-6557))
          (6558 (cl:go pc-6558))
          (6559 (cl:go pc-6559))
          (6560 (cl:go pc-6560))
          (6561 (cl:go pc-6561))
          (6562 (cl:go pc-6562))
          (6563 (cl:go pc-6563))
          (6564 (cl:go pc-6564))
          (6565 (cl:go pc-6565))
          (6566 (cl:go pc-6566))
          (6567 (cl:go pc-6567))
          (6568 (cl:go pc-6568))
          (6569 (cl:go pc-6569))
          (6570 (cl:go pc-6570))
          (6571 (cl:go pc-6571))
          (6572 (cl:go pc-6572))
          (6573 (cl:go pc-6573))
          (6574 (cl:go pc-6574))
          (6575 (cl:go pc-6575))
          (6576 (cl:go pc-6576))
          (6577 (cl:go pc-6577))
          (6578 (cl:go pc-6578))
          (6579 (cl:go pc-6579))
          (6580 (cl:go pc-6580))
          (6581 (cl:go pc-6581))
          (6582 (cl:go pc-6582))
          (6583 (cl:go pc-6583))
          (6584 (cl:go pc-6584))
          (6585 (cl:go pc-6585))
          (6586 (cl:go pc-6586))
          (6587 (cl:go pc-6587))
          (6588 (cl:go pc-6588))
          (6589 (cl:go pc-6589))
          (6590 (cl:go pc-6590))
          (6591 (cl:go pc-6591))
          (6592 (cl:go pc-6592))
          (6593 (cl:go pc-6593))
          (6594 (cl:go pc-6594))
          (6595 (cl:go pc-6595))
          (6596 (cl:go pc-6596))
          (6597 (cl:go pc-6597))
          (6598 (cl:go pc-6598))
          (6599 (cl:go pc-6599))
          (6600 (cl:go pc-6600))
          (6601 (cl:go pc-6601))
          (6602 (cl:go pc-6602))
          (6603 (cl:go pc-6603))
          (6604 (cl:go pc-6604))
          (6605 (cl:go pc-6605))
          (6606 (cl:go pc-6606))
          (6607 (cl:go pc-6607))
          (6608 (cl:go pc-6608))
          (6609 (cl:go pc-6609))
          (6610 (cl:go pc-6610))
          (6611 (cl:go pc-6611))
          (6612 (cl:go pc-6612))
          (6613 (cl:go pc-6613))
          (6614 (cl:go pc-6614))
          (6615 (cl:go pc-6615))
          (6616 (cl:go pc-6616))
          (6617 (cl:go pc-6617))
          (6618 (cl:go pc-6618))
          (6619 (cl:go pc-6619))
          (6620 (cl:go pc-6620))
          (6621 (cl:go pc-6621))
          (6622 (cl:go pc-6622))
          (6623 (cl:go pc-6623))
          (6624 (cl:go pc-6624))
          (6625 (cl:go pc-6625))
          (6626 (cl:go pc-6626))
          (6627 (cl:go pc-6627))
          (6628 (cl:go pc-6628))
          (6629 (cl:go pc-6629))
          (6630 (cl:go pc-6630))
          (6631 (cl:go pc-6631))
          (6632 (cl:go pc-6632))
          (6633 (cl:go pc-6633))
          (6634 (cl:go pc-6634))
          (6635 (cl:go pc-6635))
          (6636 (cl:go pc-6636))
          (6637 (cl:go pc-6637))
          (6638 (cl:go pc-6638))
          (6639 (cl:go pc-6639))
          (6640 (cl:go pc-6640))
          (6641 (cl:go pc-6641))
          (6642 (cl:go pc-6642))
          (6643 (cl:go pc-6643))
          (6644 (cl:go pc-6644))
          (6645 (cl:go pc-6645))
          (6646 (cl:go pc-6646))
          (6647 (cl:go pc-6647))
          (6648 (cl:go pc-6648))
          (6649 (cl:go pc-6649))
          (6650 (cl:go pc-6650))
          (6651 (cl:go pc-6651))
          (6652 (cl:go pc-6652))
          (6653 (cl:go pc-6653))
          (6654 (cl:go pc-6654))
          (6655 (cl:go pc-6655))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 6912)
        (cl:case pc
          (6656 (cl:go pc-6656))
          (6657 (cl:go pc-6657))
          (6658 (cl:go pc-6658))
          (6659 (cl:go pc-6659))
          (6660 (cl:go pc-6660))
          (6661 (cl:go pc-6661))
          (6662 (cl:go pc-6662))
          (6663 (cl:go pc-6663))
          (6664 (cl:go pc-6664))
          (6665 (cl:go pc-6665))
          (6666 (cl:go pc-6666))
          (6667 (cl:go pc-6667))
          (6668 (cl:go pc-6668))
          (6669 (cl:go pc-6669))
          (6670 (cl:go pc-6670))
          (6671 (cl:go pc-6671))
          (6672 (cl:go pc-6672))
          (6673 (cl:go pc-6673))
          (6674 (cl:go pc-6674))
          (6675 (cl:go pc-6675))
          (6676 (cl:go pc-6676))
          (6677 (cl:go pc-6677))
          (6678 (cl:go pc-6678))
          (6679 (cl:go pc-6679))
          (6680 (cl:go pc-6680))
          (6681 (cl:go pc-6681))
          (6682 (cl:go pc-6682))
          (6683 (cl:go pc-6683))
          (6684 (cl:go pc-6684))
          (6685 (cl:go pc-6685))
          (6686 (cl:go pc-6686))
          (6687 (cl:go pc-6687))
          (6688 (cl:go pc-6688))
          (6689 (cl:go pc-6689))
          (6690 (cl:go pc-6690))
          (6691 (cl:go pc-6691))
          (6692 (cl:go pc-6692))
          (6693 (cl:go pc-6693))
          (6694 (cl:go pc-6694))
          (6695 (cl:go pc-6695))
          (6696 (cl:go pc-6696))
          (6697 (cl:go pc-6697))
          (6698 (cl:go pc-6698))
          (6699 (cl:go pc-6699))
          (6700 (cl:go pc-6700))
          (6701 (cl:go pc-6701))
          (6702 (cl:go pc-6702))
          (6703 (cl:go pc-6703))
          (6704 (cl:go pc-6704))
          (6705 (cl:go pc-6705))
          (6706 (cl:go pc-6706))
          (6707 (cl:go pc-6707))
          (6708 (cl:go pc-6708))
          (6709 (cl:go pc-6709))
          (6710 (cl:go pc-6710))
          (6711 (cl:go pc-6711))
          (6712 (cl:go pc-6712))
          (6713 (cl:go pc-6713))
          (6714 (cl:go pc-6714))
          (6715 (cl:go pc-6715))
          (6716 (cl:go pc-6716))
          (6717 (cl:go pc-6717))
          (6718 (cl:go pc-6718))
          (6719 (cl:go pc-6719))
          (6720 (cl:go pc-6720))
          (6721 (cl:go pc-6721))
          (6722 (cl:go pc-6722))
          (6723 (cl:go pc-6723))
          (6724 (cl:go pc-6724))
          (6725 (cl:go pc-6725))
          (6726 (cl:go pc-6726))
          (6727 (cl:go pc-6727))
          (6728 (cl:go pc-6728))
          (6729 (cl:go pc-6729))
          (6730 (cl:go pc-6730))
          (6731 (cl:go pc-6731))
          (6732 (cl:go pc-6732))
          (6733 (cl:go pc-6733))
          (6734 (cl:go pc-6734))
          (6735 (cl:go pc-6735))
          (6736 (cl:go pc-6736))
          (6737 (cl:go pc-6737))
          (6738 (cl:go pc-6738))
          (6739 (cl:go pc-6739))
          (6740 (cl:go pc-6740))
          (6741 (cl:go pc-6741))
          (6742 (cl:go pc-6742))
          (6743 (cl:go pc-6743))
          (6744 (cl:go pc-6744))
          (6745 (cl:go pc-6745))
          (6746 (cl:go pc-6746))
          (6747 (cl:go pc-6747))
          (6748 (cl:go pc-6748))
          (6749 (cl:go pc-6749))
          (6750 (cl:go pc-6750))
          (6751 (cl:go pc-6751))
          (6752 (cl:go pc-6752))
          (6753 (cl:go pc-6753))
          (6754 (cl:go pc-6754))
          (6755 (cl:go pc-6755))
          (6756 (cl:go pc-6756))
          (6757 (cl:go pc-6757))
          (6758 (cl:go pc-6758))
          (6759 (cl:go pc-6759))
          (6760 (cl:go pc-6760))
          (6761 (cl:go pc-6761))
          (6762 (cl:go pc-6762))
          (6763 (cl:go pc-6763))
          (6764 (cl:go pc-6764))
          (6765 (cl:go pc-6765))
          (6766 (cl:go pc-6766))
          (6767 (cl:go pc-6767))
          (6768 (cl:go pc-6768))
          (6769 (cl:go pc-6769))
          (6770 (cl:go pc-6770))
          (6771 (cl:go pc-6771))
          (6772 (cl:go pc-6772))
          (6773 (cl:go pc-6773))
          (6774 (cl:go pc-6774))
          (6775 (cl:go pc-6775))
          (6776 (cl:go pc-6776))
          (6777 (cl:go pc-6777))
          (6778 (cl:go pc-6778))
          (6779 (cl:go pc-6779))
          (6780 (cl:go pc-6780))
          (6781 (cl:go pc-6781))
          (6782 (cl:go pc-6782))
          (6783 (cl:go pc-6783))
          (6784 (cl:go pc-6784))
          (6785 (cl:go pc-6785))
          (6786 (cl:go pc-6786))
          (6787 (cl:go pc-6787))
          (6788 (cl:go pc-6788))
          (6789 (cl:go pc-6789))
          (6790 (cl:go pc-6790))
          (6791 (cl:go pc-6791))
          (6792 (cl:go pc-6792))
          (6793 (cl:go pc-6793))
          (6794 (cl:go pc-6794))
          (6795 (cl:go pc-6795))
          (6796 (cl:go pc-6796))
          (6797 (cl:go pc-6797))
          (6798 (cl:go pc-6798))
          (6799 (cl:go pc-6799))
          (6800 (cl:go pc-6800))
          (6801 (cl:go pc-6801))
          (6802 (cl:go pc-6802))
          (6803 (cl:go pc-6803))
          (6804 (cl:go pc-6804))
          (6805 (cl:go pc-6805))
          (6806 (cl:go pc-6806))
          (6807 (cl:go pc-6807))
          (6808 (cl:go pc-6808))
          (6809 (cl:go pc-6809))
          (6810 (cl:go pc-6810))
          (6811 (cl:go pc-6811))
          (6812 (cl:go pc-6812))
          (6813 (cl:go pc-6813))
          (6814 (cl:go pc-6814))
          (6815 (cl:go pc-6815))
          (6816 (cl:go pc-6816))
          (6817 (cl:go pc-6817))
          (6818 (cl:go pc-6818))
          (6819 (cl:go pc-6819))
          (6820 (cl:go pc-6820))
          (6821 (cl:go pc-6821))
          (6822 (cl:go pc-6822))
          (6823 (cl:go pc-6823))
          (6824 (cl:go pc-6824))
          (6825 (cl:go pc-6825))
          (6826 (cl:go pc-6826))
          (6827 (cl:go pc-6827))
          (6828 (cl:go pc-6828))
          (6829 (cl:go pc-6829))
          (6830 (cl:go pc-6830))
          (6831 (cl:go pc-6831))
          (6832 (cl:go pc-6832))
          (6833 (cl:go pc-6833))
          (6834 (cl:go pc-6834))
          (6835 (cl:go pc-6835))
          (6836 (cl:go pc-6836))
          (6837 (cl:go pc-6837))
          (6838 (cl:go pc-6838))
          (6839 (cl:go pc-6839))
          (6840 (cl:go pc-6840))
          (6841 (cl:go pc-6841))
          (6842 (cl:go pc-6842))
          (6843 (cl:go pc-6843))
          (6844 (cl:go pc-6844))
          (6845 (cl:go pc-6845))
          (6846 (cl:go pc-6846))
          (6847 (cl:go pc-6847))
          (6848 (cl:go pc-6848))
          (6849 (cl:go pc-6849))
          (6850 (cl:go pc-6850))
          (6851 (cl:go pc-6851))
          (6852 (cl:go pc-6852))
          (6853 (cl:go pc-6853))
          (6854 (cl:go pc-6854))
          (6855 (cl:go pc-6855))
          (6856 (cl:go pc-6856))
          (6857 (cl:go pc-6857))
          (6858 (cl:go pc-6858))
          (6859 (cl:go pc-6859))
          (6860 (cl:go pc-6860))
          (6861 (cl:go pc-6861))
          (6862 (cl:go pc-6862))
          (6863 (cl:go pc-6863))
          (6864 (cl:go pc-6864))
          (6865 (cl:go pc-6865))
          (6866 (cl:go pc-6866))
          (6867 (cl:go pc-6867))
          (6868 (cl:go pc-6868))
          (6869 (cl:go pc-6869))
          (6870 (cl:go pc-6870))
          (6871 (cl:go pc-6871))
          (6872 (cl:go pc-6872))
          (6873 (cl:go pc-6873))
          (6874 (cl:go pc-6874))
          (6875 (cl:go pc-6875))
          (6876 (cl:go pc-6876))
          (6877 (cl:go pc-6877))
          (6878 (cl:go pc-6878))
          (6879 (cl:go pc-6879))
          (6880 (cl:go pc-6880))
          (6881 (cl:go pc-6881))
          (6882 (cl:go pc-6882))
          (6883 (cl:go pc-6883))
          (6884 (cl:go pc-6884))
          (6885 (cl:go pc-6885))
          (6886 (cl:go pc-6886))
          (6887 (cl:go pc-6887))
          (6888 (cl:go pc-6888))
          (6889 (cl:go pc-6889))
          (6890 (cl:go pc-6890))
          (6891 (cl:go pc-6891))
          (6892 (cl:go pc-6892))
          (6893 (cl:go pc-6893))
          (6894 (cl:go pc-6894))
          (6895 (cl:go pc-6895))
          (6896 (cl:go pc-6896))
          (6897 (cl:go pc-6897))
          (6898 (cl:go pc-6898))
          (6899 (cl:go pc-6899))
          (6900 (cl:go pc-6900))
          (6901 (cl:go pc-6901))
          (6902 (cl:go pc-6902))
          (6903 (cl:go pc-6903))
          (6904 (cl:go pc-6904))
          (6905 (cl:go pc-6905))
          (6906 (cl:go pc-6906))
          (6907 (cl:go pc-6907))
          (6908 (cl:go pc-6908))
          (6909 (cl:go pc-6909))
          (6910 (cl:go pc-6910))
          (6911 (cl:go pc-6911))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 7168)
        (cl:case pc
          (6912 (cl:go pc-6912))
          (6913 (cl:go pc-6913))
          (6914 (cl:go pc-6914))
          (6915 (cl:go pc-6915))
          (6916 (cl:go pc-6916))
          (6917 (cl:go pc-6917))
          (6918 (cl:go pc-6918))
          (6919 (cl:go pc-6919))
          (6920 (cl:go pc-6920))
          (6921 (cl:go pc-6921))
          (6922 (cl:go pc-6922))
          (6923 (cl:go pc-6923))
          (6924 (cl:go pc-6924))
          (6925 (cl:go pc-6925))
          (6926 (cl:go pc-6926))
          (6927 (cl:go pc-6927))
          (6928 (cl:go pc-6928))
          (6929 (cl:go pc-6929))
          (6930 (cl:go pc-6930))
          (6931 (cl:go pc-6931))
          (6932 (cl:go pc-6932))
          (6933 (cl:go pc-6933))
          (6934 (cl:go pc-6934))
          (6935 (cl:go pc-6935))
          (6936 (cl:go pc-6936))
          (6937 (cl:go pc-6937))
          (6938 (cl:go pc-6938))
          (6939 (cl:go pc-6939))
          (6940 (cl:go pc-6940))
          (6941 (cl:go pc-6941))
          (6942 (cl:go pc-6942))
          (6943 (cl:go pc-6943))
          (6944 (cl:go pc-6944))
          (6945 (cl:go pc-6945))
          (6946 (cl:go pc-6946))
          (6947 (cl:go pc-6947))
          (6948 (cl:go pc-6948))
          (6949 (cl:go pc-6949))
          (6950 (cl:go pc-6950))
          (6951 (cl:go pc-6951))
          (6952 (cl:go pc-6952))
          (6953 (cl:go pc-6953))
          (6954 (cl:go pc-6954))
          (6955 (cl:go pc-6955))
          (6956 (cl:go pc-6956))
          (6957 (cl:go pc-6957))
          (6958 (cl:go pc-6958))
          (6959 (cl:go pc-6959))
          (6960 (cl:go pc-6960))
          (6961 (cl:go pc-6961))
          (6962 (cl:go pc-6962))
          (6963 (cl:go pc-6963))
          (6964 (cl:go pc-6964))
          (6965 (cl:go pc-6965))
          (6966 (cl:go pc-6966))
          (6967 (cl:go pc-6967))
          (6968 (cl:go pc-6968))
          (6969 (cl:go pc-6969))
          (6970 (cl:go pc-6970))
          (6971 (cl:go pc-6971))
          (6972 (cl:go pc-6972))
          (6973 (cl:go pc-6973))
          (6974 (cl:go pc-6974))
          (6975 (cl:go pc-6975))
          (6976 (cl:go pc-6976))
          (6977 (cl:go pc-6977))
          (6978 (cl:go pc-6978))
          (6979 (cl:go pc-6979))
          (6980 (cl:go pc-6980))
          (6981 (cl:go pc-6981))
          (6982 (cl:go pc-6982))
          (6983 (cl:go pc-6983))
          (6984 (cl:go pc-6984))
          (6985 (cl:go pc-6985))
          (6986 (cl:go pc-6986))
          (6987 (cl:go pc-6987))
          (6988 (cl:go pc-6988))
          (6989 (cl:go pc-6989))
          (6990 (cl:go pc-6990))
          (6991 (cl:go pc-6991))
          (6992 (cl:go pc-6992))
          (6993 (cl:go pc-6993))
          (6994 (cl:go pc-6994))
          (6995 (cl:go pc-6995))
          (6996 (cl:go pc-6996))
          (6997 (cl:go pc-6997))
          (6998 (cl:go pc-6998))
          (6999 (cl:go pc-6999))
          (7000 (cl:go pc-7000))
          (7001 (cl:go pc-7001))
          (7002 (cl:go pc-7002))
          (7003 (cl:go pc-7003))
          (7004 (cl:go pc-7004))
          (7005 (cl:go pc-7005))
          (7006 (cl:go pc-7006))
          (7007 (cl:go pc-7007))
          (7008 (cl:go pc-7008))
          (7009 (cl:go pc-7009))
          (7010 (cl:go pc-7010))
          (7011 (cl:go pc-7011))
          (7012 (cl:go pc-7012))
          (7013 (cl:go pc-7013))
          (7014 (cl:go pc-7014))
          (7015 (cl:go pc-7015))
          (7016 (cl:go pc-7016))
          (7017 (cl:go pc-7017))
          (7018 (cl:go pc-7018))
          (7019 (cl:go pc-7019))
          (7020 (cl:go pc-7020))
          (7021 (cl:go pc-7021))
          (7022 (cl:go pc-7022))
          (7023 (cl:go pc-7023))
          (7024 (cl:go pc-7024))
          (7025 (cl:go pc-7025))
          (7026 (cl:go pc-7026))
          (7027 (cl:go pc-7027))
          (7028 (cl:go pc-7028))
          (7029 (cl:go pc-7029))
          (7030 (cl:go pc-7030))
          (7031 (cl:go pc-7031))
          (7032 (cl:go pc-7032))
          (7033 (cl:go pc-7033))
          (7034 (cl:go pc-7034))
          (7035 (cl:go pc-7035))
          (7036 (cl:go pc-7036))
          (7037 (cl:go pc-7037))
          (7038 (cl:go pc-7038))
          (7039 (cl:go pc-7039))
          (7040 (cl:go pc-7040))
          (7041 (cl:go pc-7041))
          (7042 (cl:go pc-7042))
          (7043 (cl:go pc-7043))
          (7044 (cl:go pc-7044))
          (7045 (cl:go pc-7045))
          (7046 (cl:go pc-7046))
          (7047 (cl:go pc-7047))
          (7048 (cl:go pc-7048))
          (7049 (cl:go pc-7049))
          (7050 (cl:go pc-7050))
          (7051 (cl:go pc-7051))
          (7052 (cl:go pc-7052))
          (7053 (cl:go pc-7053))
          (7054 (cl:go pc-7054))
          (7055 (cl:go pc-7055))
          (7056 (cl:go pc-7056))
          (7057 (cl:go pc-7057))
          (7058 (cl:go pc-7058))
          (7059 (cl:go pc-7059))
          (7060 (cl:go pc-7060))
          (7061 (cl:go pc-7061))
          (7062 (cl:go pc-7062))
          (7063 (cl:go pc-7063))
          (7064 (cl:go pc-7064))
          (7065 (cl:go pc-7065))
          (7066 (cl:go pc-7066))
          (7067 (cl:go pc-7067))
          (7068 (cl:go pc-7068))
          (7069 (cl:go pc-7069))
          (7070 (cl:go pc-7070))
          (7071 (cl:go pc-7071))
          (7072 (cl:go pc-7072))
          (7073 (cl:go pc-7073))
          (7074 (cl:go pc-7074))
          (7075 (cl:go pc-7075))
          (7076 (cl:go pc-7076))
          (7077 (cl:go pc-7077))
          (7078 (cl:go pc-7078))
          (7079 (cl:go pc-7079))
          (7080 (cl:go pc-7080))
          (7081 (cl:go pc-7081))
          (7082 (cl:go pc-7082))
          (7083 (cl:go pc-7083))
          (7084 (cl:go pc-7084))
          (7085 (cl:go pc-7085))
          (7086 (cl:go pc-7086))
          (7087 (cl:go pc-7087))
          (7088 (cl:go pc-7088))
          (7089 (cl:go pc-7089))
          (7090 (cl:go pc-7090))
          (7091 (cl:go pc-7091))
          (7092 (cl:go pc-7092))
          (7093 (cl:go pc-7093))
          (7094 (cl:go pc-7094))
          (7095 (cl:go pc-7095))
          (7096 (cl:go pc-7096))
          (7097 (cl:go pc-7097))
          (7098 (cl:go pc-7098))
          (7099 (cl:go pc-7099))
          (7100 (cl:go pc-7100))
          (7101 (cl:go pc-7101))
          (7102 (cl:go pc-7102))
          (7103 (cl:go pc-7103))
          (7104 (cl:go pc-7104))
          (7105 (cl:go pc-7105))
          (7106 (cl:go pc-7106))
          (7107 (cl:go pc-7107))
          (7108 (cl:go pc-7108))
          (7109 (cl:go pc-7109))
          (7110 (cl:go pc-7110))
          (7111 (cl:go pc-7111))
          (7112 (cl:go pc-7112))
          (7113 (cl:go pc-7113))
          (7114 (cl:go pc-7114))
          (7115 (cl:go pc-7115))
          (7116 (cl:go pc-7116))
          (7117 (cl:go pc-7117))
          (7118 (cl:go pc-7118))
          (7119 (cl:go pc-7119))
          (7120 (cl:go pc-7120))
          (7121 (cl:go pc-7121))
          (7122 (cl:go pc-7122))
          (7123 (cl:go pc-7123))
          (7124 (cl:go pc-7124))
          (7125 (cl:go pc-7125))
          (7126 (cl:go pc-7126))
          (7127 (cl:go pc-7127))
          (7128 (cl:go pc-7128))
          (7129 (cl:go pc-7129))
          (7130 (cl:go pc-7130))
          (7131 (cl:go pc-7131))
          (7132 (cl:go pc-7132))
          (7133 (cl:go pc-7133))
          (7134 (cl:go pc-7134))
          (7135 (cl:go pc-7135))
          (7136 (cl:go pc-7136))
          (7137 (cl:go pc-7137))
          (7138 (cl:go pc-7138))
          (7139 (cl:go pc-7139))
          (7140 (cl:go pc-7140))
          (7141 (cl:go pc-7141))
          (7142 (cl:go pc-7142))
          (7143 (cl:go pc-7143))
          (7144 (cl:go pc-7144))
          (7145 (cl:go pc-7145))
          (7146 (cl:go pc-7146))
          (7147 (cl:go pc-7147))
          (7148 (cl:go pc-7148))
          (7149 (cl:go pc-7149))
          (7150 (cl:go pc-7150))
          (7151 (cl:go pc-7151))
          (7152 (cl:go pc-7152))
          (7153 (cl:go pc-7153))
          (7154 (cl:go pc-7154))
          (7155 (cl:go pc-7155))
          (7156 (cl:go pc-7156))
          (7157 (cl:go pc-7157))
          (7158 (cl:go pc-7158))
          (7159 (cl:go pc-7159))
          (7160 (cl:go pc-7160))
          (7161 (cl:go pc-7161))
          (7162 (cl:go pc-7162))
          (7163 (cl:go pc-7163))
          (7164 (cl:go pc-7164))
          (7165 (cl:go pc-7165))
          (7166 (cl:go pc-7166))
          (7167 (cl:go pc-7167))
          (cl:t (cl:go chunk-exit))))
       ((cl:< pc 7420)
        (cl:case pc
          (7168 (cl:go pc-7168))
          (7169 (cl:go pc-7169))
          (7170 (cl:go pc-7170))
          (7171 (cl:go pc-7171))
          (7172 (cl:go pc-7172))
          (7173 (cl:go pc-7173))
          (7174 (cl:go pc-7174))
          (7175 (cl:go pc-7175))
          (7176 (cl:go pc-7176))
          (7177 (cl:go pc-7177))
          (7178 (cl:go pc-7178))
          (7179 (cl:go pc-7179))
          (7180 (cl:go pc-7180))
          (7181 (cl:go pc-7181))
          (7182 (cl:go pc-7182))
          (7183 (cl:go pc-7183))
          (7184 (cl:go pc-7184))
          (7185 (cl:go pc-7185))
          (7186 (cl:go pc-7186))
          (7187 (cl:go pc-7187))
          (7188 (cl:go pc-7188))
          (7189 (cl:go pc-7189))
          (7190 (cl:go pc-7190))
          (7191 (cl:go pc-7191))
          (7192 (cl:go pc-7192))
          (7193 (cl:go pc-7193))
          (7194 (cl:go pc-7194))
          (7195 (cl:go pc-7195))
          (7196 (cl:go pc-7196))
          (7197 (cl:go pc-7197))
          (7198 (cl:go pc-7198))
          (7199 (cl:go pc-7199))
          (7200 (cl:go pc-7200))
          (7201 (cl:go pc-7201))
          (7202 (cl:go pc-7202))
          (7203 (cl:go pc-7203))
          (7204 (cl:go pc-7204))
          (7205 (cl:go pc-7205))
          (7206 (cl:go pc-7206))
          (7207 (cl:go pc-7207))
          (7208 (cl:go pc-7208))
          (7209 (cl:go pc-7209))
          (7210 (cl:go pc-7210))
          (7211 (cl:go pc-7211))
          (7212 (cl:go pc-7212))
          (7213 (cl:go pc-7213))
          (7214 (cl:go pc-7214))
          (7215 (cl:go pc-7215))
          (7216 (cl:go pc-7216))
          (7217 (cl:go pc-7217))
          (7218 (cl:go pc-7218))
          (7219 (cl:go pc-7219))
          (7220 (cl:go pc-7220))
          (7221 (cl:go pc-7221))
          (7222 (cl:go pc-7222))
          (7223 (cl:go pc-7223))
          (7224 (cl:go pc-7224))
          (7225 (cl:go pc-7225))
          (7226 (cl:go pc-7226))
          (7227 (cl:go pc-7227))
          (7228 (cl:go pc-7228))
          (7229 (cl:go pc-7229))
          (7230 (cl:go pc-7230))
          (7231 (cl:go pc-7231))
          (7232 (cl:go pc-7232))
          (7233 (cl:go pc-7233))
          (7234 (cl:go pc-7234))
          (7235 (cl:go pc-7235))
          (7236 (cl:go pc-7236))
          (7237 (cl:go pc-7237))
          (7238 (cl:go pc-7238))
          (7239 (cl:go pc-7239))
          (7240 (cl:go pc-7240))
          (7241 (cl:go pc-7241))
          (7242 (cl:go pc-7242))
          (7243 (cl:go pc-7243))
          (7244 (cl:go pc-7244))
          (7245 (cl:go pc-7245))
          (7246 (cl:go pc-7246))
          (7247 (cl:go pc-7247))
          (7248 (cl:go pc-7248))
          (7249 (cl:go pc-7249))
          (7250 (cl:go pc-7250))
          (7251 (cl:go pc-7251))
          (7252 (cl:go pc-7252))
          (7253 (cl:go pc-7253))
          (7254 (cl:go pc-7254))
          (7255 (cl:go pc-7255))
          (7256 (cl:go pc-7256))
          (7257 (cl:go pc-7257))
          (7258 (cl:go pc-7258))
          (7259 (cl:go pc-7259))
          (7260 (cl:go pc-7260))
          (7261 (cl:go pc-7261))
          (7262 (cl:go pc-7262))
          (7263 (cl:go pc-7263))
          (7264 (cl:go pc-7264))
          (7265 (cl:go pc-7265))
          (7266 (cl:go pc-7266))
          (7267 (cl:go pc-7267))
          (7268 (cl:go pc-7268))
          (7269 (cl:go pc-7269))
          (7270 (cl:go pc-7270))
          (7271 (cl:go pc-7271))
          (7272 (cl:go pc-7272))
          (7273 (cl:go pc-7273))
          (7274 (cl:go pc-7274))
          (7275 (cl:go pc-7275))
          (7276 (cl:go pc-7276))
          (7277 (cl:go pc-7277))
          (7278 (cl:go pc-7278))
          (7279 (cl:go pc-7279))
          (7280 (cl:go pc-7280))
          (7281 (cl:go pc-7281))
          (7282 (cl:go pc-7282))
          (7283 (cl:go pc-7283))
          (7284 (cl:go pc-7284))
          (7285 (cl:go pc-7285))
          (7286 (cl:go pc-7286))
          (7287 (cl:go pc-7287))
          (7288 (cl:go pc-7288))
          (7289 (cl:go pc-7289))
          (7290 (cl:go pc-7290))
          (7291 (cl:go pc-7291))
          (7292 (cl:go pc-7292))
          (7293 (cl:go pc-7293))
          (7294 (cl:go pc-7294))
          (7295 (cl:go pc-7295))
          (7296 (cl:go pc-7296))
          (7297 (cl:go pc-7297))
          (7298 (cl:go pc-7298))
          (7299 (cl:go pc-7299))
          (7300 (cl:go pc-7300))
          (7301 (cl:go pc-7301))
          (7302 (cl:go pc-7302))
          (7303 (cl:go pc-7303))
          (7304 (cl:go pc-7304))
          (7305 (cl:go pc-7305))
          (7306 (cl:go pc-7306))
          (7307 (cl:go pc-7307))
          (7308 (cl:go pc-7308))
          (7309 (cl:go pc-7309))
          (7310 (cl:go pc-7310))
          (7311 (cl:go pc-7311))
          (7312 (cl:go pc-7312))
          (7313 (cl:go pc-7313))
          (7314 (cl:go pc-7314))
          (7315 (cl:go pc-7315))
          (7316 (cl:go pc-7316))
          (7317 (cl:go pc-7317))
          (7318 (cl:go pc-7318))
          (7319 (cl:go pc-7319))
          (7320 (cl:go pc-7320))
          (7321 (cl:go pc-7321))
          (7322 (cl:go pc-7322))
          (7323 (cl:go pc-7323))
          (7324 (cl:go pc-7324))
          (7325 (cl:go pc-7325))
          (7326 (cl:go pc-7326))
          (7327 (cl:go pc-7327))
          (7328 (cl:go pc-7328))
          (7329 (cl:go pc-7329))
          (7330 (cl:go pc-7330))
          (7331 (cl:go pc-7331))
          (7332 (cl:go pc-7332))
          (7333 (cl:go pc-7333))
          (7334 (cl:go pc-7334))
          (7335 (cl:go pc-7335))
          (7336 (cl:go pc-7336))
          (7337 (cl:go pc-7337))
          (7338 (cl:go pc-7338))
          (7339 (cl:go pc-7339))
          (7340 (cl:go pc-7340))
          (7341 (cl:go pc-7341))
          (7342 (cl:go pc-7342))
          (7343 (cl:go pc-7343))
          (7344 (cl:go pc-7344))
          (7345 (cl:go pc-7345))
          (7346 (cl:go pc-7346))
          (7347 (cl:go pc-7347))
          (7348 (cl:go pc-7348))
          (7349 (cl:go pc-7349))
          (7350 (cl:go pc-7350))
          (7351 (cl:go pc-7351))
          (7352 (cl:go pc-7352))
          (7353 (cl:go pc-7353))
          (7354 (cl:go pc-7354))
          (7355 (cl:go pc-7355))
          (7356 (cl:go pc-7356))
          (7357 (cl:go pc-7357))
          (7358 (cl:go pc-7358))
          (7359 (cl:go pc-7359))
          (7360 (cl:go pc-7360))
          (7361 (cl:go pc-7361))
          (7362 (cl:go pc-7362))
          (7363 (cl:go pc-7363))
          (7364 (cl:go pc-7364))
          (7365 (cl:go pc-7365))
          (7366 (cl:go pc-7366))
          (7367 (cl:go pc-7367))
          (7368 (cl:go pc-7368))
          (7369 (cl:go pc-7369))
          (7370 (cl:go pc-7370))
          (7371 (cl:go pc-7371))
          (7372 (cl:go pc-7372))
          (7373 (cl:go pc-7373))
          (7374 (cl:go pc-7374))
          (7375 (cl:go pc-7375))
          (7376 (cl:go pc-7376))
          (7377 (cl:go pc-7377))
          (7378 (cl:go pc-7378))
          (7379 (cl:go pc-7379))
          (7380 (cl:go pc-7380))
          (7381 (cl:go pc-7381))
          (7382 (cl:go pc-7382))
          (7383 (cl:go pc-7383))
          (7384 (cl:go pc-7384))
          (7385 (cl:go pc-7385))
          (7386 (cl:go pc-7386))
          (7387 (cl:go pc-7387))
          (7388 (cl:go pc-7388))
          (7389 (cl:go pc-7389))
          (7390 (cl:go pc-7390))
          (7391 (cl:go pc-7391))
          (7392 (cl:go pc-7392))
          (7393 (cl:go pc-7393))
          (7394 (cl:go pc-7394))
          (7395 (cl:go pc-7395))
          (7396 (cl:go pc-7396))
          (7397 (cl:go pc-7397))
          (7398 (cl:go pc-7398))
          (7399 (cl:go pc-7399))
          (7400 (cl:go pc-7400))
          (7401 (cl:go pc-7401))
          (7402 (cl:go pc-7402))
          (7403 (cl:go pc-7403))
          (7404 (cl:go pc-7404))
          (7405 (cl:go pc-7405))
          (7406 (cl:go pc-7406))
          (7407 (cl:go pc-7407))
          (7408 (cl:go pc-7408))
          (7409 (cl:go pc-7409))
          (7410 (cl:go pc-7410))
          (7411 (cl:go pc-7411))
          (7412 (cl:go pc-7412))
          (7413 (cl:go pc-7413))
          (7414 (cl:go pc-7414))
          (7415 (cl:go pc-7415))
          (7416 (cl:go pc-7416))
          (7417 (cl:go pc-7417))
          (7418 (cl:go pc-7418))
          (7419 (cl:go pc-7419))
          (cl:t (cl:go chunk-exit))))
       (cl:t (cl:go chunk-exit)))
     pc-4096
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4097)
     pc-4097
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4098)
     pc-4098
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4099
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4100)
     pc-4100
       (cl:setf pc 4102) (cl:go pc-4102)
     pc-4101
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4102)
     pc-4102
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4103)
     pc-4103
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4104)
     pc-4104
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4105)
     pc-4105
       (cl:when flag (cl:setf pc 4120) (cl:go pc-4120))
     pc-4106
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4107)
     pc-4107
       (cl:when flag (cl:setf pc 4113) (cl:go pc-4113))
     pc-4108
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4109)
     pc-4109
       (cl:when flag (cl:setf pc 4118) (cl:go pc-4118))
     pc-4110
       (cl:setf continue (cl:cons '|compilation-unit| 4121))
       (cl:setf pc 4111)
     pc-4111
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4112)
     pc-4112
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4113
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4114)
     pc-4114
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4115)
     pc-4115
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4116)
     pc-4116
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4117)
     pc-4117
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4118
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4119)
     pc-4119
       (cl:setf pc 4121) (cl:go pc-4121)
     pc-4120
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4121)
     pc-4121
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4122)
     pc-4122
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 4123)
     pc-4123
       (cl:when flag (cl:setf pc 4166) (cl:go pc-4166))
     pc-4124
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 4125)
     pc-4125
       (cl:push proc stack)
       (cl:setf pc 4126)
     pc-4126
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 4127)
     pc-4127
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4128)
     pc-4128
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4129)
     pc-4129
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4130)
     pc-4130
       (cl:when flag (cl:setf pc 4145) (cl:go pc-4145))
     pc-4131
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4132)
     pc-4132
       (cl:when flag (cl:setf pc 4138) (cl:go pc-4138))
     pc-4133
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4134)
     pc-4134
       (cl:when flag (cl:setf pc 4143) (cl:go pc-4143))
     pc-4135
       (cl:setf continue (cl:cons '|compilation-unit| 4146))
       (cl:setf pc 4136)
     pc-4136
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4137)
     pc-4137
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4138
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4139)
     pc-4139
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4140)
     pc-4140
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4141)
     pc-4141
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4142)
     pc-4142
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4143
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4144)
     pc-4144
       (cl:setf pc 4146) (cl:go pc-4146)
     pc-4145
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4146)
     pc-4146
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4147)
     pc-4147
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4148)
     pc-4148
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4149)
     pc-4149
       (cl:when flag (cl:setf pc 4164) (cl:go pc-4164))
     pc-4150
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4151)
     pc-4151
       (cl:when flag (cl:setf pc 4157) (cl:go pc-4157))
     pc-4152
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4153)
     pc-4153
       (cl:when flag (cl:setf pc 4162) (cl:go pc-4162))
     pc-4154
       (cl:setf continue (cl:cons '|compilation-unit| 4186))
       (cl:setf pc 4155)
     pc-4155
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4156)
     pc-4156
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4157
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4158)
     pc-4158
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4159)
     pc-4159
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4160)
     pc-4160
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4161)
     pc-4161
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4162
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4163)
     pc-4163
       (cl:setf pc 4186) (cl:go pc-4186)
     pc-4164
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4165)
     pc-4165
       (cl:setf pc 4186) (cl:go pc-4186)
     pc-4166
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 4167)
     pc-4167
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4168)
     pc-4168
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4169)
     pc-4169
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4170)
     pc-4170
       (cl:when flag (cl:setf pc 4185) (cl:go pc-4185))
     pc-4171
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4172)
     pc-4172
       (cl:when flag (cl:setf pc 4178) (cl:go pc-4178))
     pc-4173
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4174)
     pc-4174
       (cl:when flag (cl:setf pc 4183) (cl:go pc-4183))
     pc-4175
       (cl:setf continue (cl:cons '|compilation-unit| 4186))
       (cl:setf pc 4176)
     pc-4176
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4177)
     pc-4177
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4178
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4179)
     pc-4179
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4180)
     pc-4180
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4181)
     pc-4181
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4182)
     pc-4182
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4183
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4184)
     pc-4184
       (cl:setf pc 4186) (cl:go pc-4186)
     pc-4185
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4186)
     pc-4186
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 4187)
     pc-4187
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4188)
     pc-4188
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4189)
     pc-4189
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4190)
     pc-4190
       (cl:when flag (cl:setf pc 4205) (cl:go pc-4205))
     pc-4191
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4192)
     pc-4192
       (cl:when flag (cl:setf pc 4198) (cl:go pc-4198))
     pc-4193
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4194)
     pc-4194
       (cl:when flag (cl:setf pc 4203) (cl:go pc-4203))
     pc-4195
       (cl:setf continue (cl:cons '|compilation-unit| 4208))
       (cl:setf pc 4196)
     pc-4196
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4197)
     pc-4197
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4198
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4199)
     pc-4199
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4200)
     pc-4200
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4201)
     pc-4201
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4202)
     pc-4202
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4203
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4204)
     pc-4204
       (cl:setf pc 4208) (cl:go pc-4208)
     pc-4205
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4206)
     pc-4206
       (cl:setf pc 4208) (cl:go pc-4208)
     pc-4207
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 4208)
     pc-4208
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4209)
     pc-4209
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4210)
     pc-4210
       (cl:push argl stack)
       (cl:setf pc 4211)
     pc-4211
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 4212)
     pc-4212
       (cl:push proc stack)
       (cl:setf pc 4213)
     pc-4213
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 4214)
     pc-4214
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4215)
     pc-4215
       (cl:push argl stack)
       (cl:setf pc 4216)
     pc-4216
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|compile-form| env))
       (cl:setf pc 4217)
     pc-4217
       (cl:push proc stack)
       (cl:setf pc 4218)
     pc-4218
       (cl:push env stack)
       (cl:setf pc 4219)
     pc-4219
       (cl:push env stack)
       (cl:setf pc 4220)
     pc-4220
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 4221)
     pc-4221
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4222)
     pc-4222
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4223)
     pc-4223
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4224)
     pc-4224
       (cl:when flag (cl:setf pc 4239) (cl:go pc-4239))
     pc-4225
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4226)
     pc-4226
       (cl:when flag (cl:setf pc 4232) (cl:go pc-4232))
     pc-4227
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4228)
     pc-4228
       (cl:when flag (cl:setf pc 4237) (cl:go pc-4237))
     pc-4229
       (cl:setf continue (cl:cons '|compilation-unit| 4240))
       (cl:setf pc 4230)
     pc-4230
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4231)
     pc-4231
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4232
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4233)
     pc-4233
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4234)
     pc-4234
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4235)
     pc-4235
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4236)
     pc-4236
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4237
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4238)
     pc-4238
       (cl:setf pc 4240) (cl:go pc-4240)
     pc-4239
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4240)
     pc-4240
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4241)
     pc-4241
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 4242)
     pc-4242
       (cl:when flag (cl:setf pc 4289) (cl:go pc-4289))
     pc-4243
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eq?| env))
       (cl:setf pc 4244)
     pc-4244
       (cl:push proc stack)
       (cl:setf pc 4245)
     pc-4245
       (cl:setf val '|define-macro|)
       (cl:setf pc 4246)
     pc-4246
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4247)
     pc-4247
       (cl:push argl stack)
       (cl:setf pc 4248)
     pc-4248
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 4249)
     pc-4249
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4250)
     pc-4250
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4251)
     pc-4251
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4252)
     pc-4252
       (cl:when flag (cl:setf pc 4267) (cl:go pc-4267))
     pc-4253
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4254)
     pc-4254
       (cl:when flag (cl:setf pc 4260) (cl:go pc-4260))
     pc-4255
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4256)
     pc-4256
       (cl:when flag (cl:setf pc 4265) (cl:go pc-4265))
     pc-4257
       (cl:setf continue (cl:cons '|compilation-unit| 4268))
       (cl:setf pc 4258)
     pc-4258
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4259)
     pc-4259
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4260
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4261)
     pc-4261
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4262)
     pc-4262
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4263)
     pc-4263
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4264)
     pc-4264
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4265
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4266)
     pc-4266
       (cl:setf pc 4268) (cl:go pc-4268)
     pc-4267
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4268)
     pc-4268
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 4269)
     pc-4269
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4270)
     pc-4270
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4271)
     pc-4271
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4272)
     pc-4272
       (cl:when flag (cl:setf pc 4287) (cl:go pc-4287))
     pc-4273
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4274)
     pc-4274
       (cl:when flag (cl:setf pc 4280) (cl:go pc-4280))
     pc-4275
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4276)
     pc-4276
       (cl:when flag (cl:setf pc 4285) (cl:go pc-4285))
     pc-4277
       (cl:setf continue (cl:cons '|compilation-unit| 4290))
       (cl:setf pc 4278)
     pc-4278
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4279)
     pc-4279
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4280
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4281)
     pc-4281
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4282)
     pc-4282
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4283)
     pc-4283
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4284)
     pc-4284
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4285
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4286)
     pc-4286
       (cl:setf pc 4290) (cl:go pc-4290)
     pc-4287
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4288)
     pc-4288
       (cl:setf pc 4290) (cl:go pc-4290)
     pc-4289
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 4290)
     pc-4290
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4291)
     pc-4291
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 4292)
     pc-4292
       (cl:when flag (cl:setf pc 4314) (cl:go pc-4314))
     pc-4293
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 2 1 env))
       (cl:setf pc 4294)
     pc-4294
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4295)
     pc-4295
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4296)
     pc-4296
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4297)
     pc-4297
       (cl:when flag (cl:setf pc 4312) (cl:go pc-4312))
     pc-4298
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4299)
     pc-4299
       (cl:when flag (cl:setf pc 4305) (cl:go pc-4305))
     pc-4300
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4301)
     pc-4301
       (cl:when flag (cl:setf pc 4310) (cl:go pc-4310))
     pc-4302
       (cl:setf continue (cl:cons '|compilation-unit| 4315))
       (cl:setf pc 4303)
     pc-4303
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4304)
     pc-4304
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4305
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4306)
     pc-4306
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4307)
     pc-4307
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4308)
     pc-4308
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4309)
     pc-4309
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4310
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4311)
     pc-4311
       (cl:setf pc 4315) (cl:go pc-4315)
     pc-4312
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4313)
     pc-4313
       (cl:setf pc 4315) (cl:go pc-4315)
     pc-4314
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4315)
     pc-4315
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4316)
     pc-4316
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4317)
     pc-4317
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4318)
     pc-4318
       (cl:when flag (cl:setf pc 4333) (cl:go pc-4333))
     pc-4319
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4320)
     pc-4320
       (cl:when flag (cl:setf pc 4326) (cl:go pc-4326))
     pc-4321
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4322)
     pc-4322
       (cl:when flag (cl:setf pc 4331) (cl:go pc-4331))
     pc-4323
       (cl:setf continue (cl:cons '|compilation-unit| 4334))
       (cl:setf pc 4324)
     pc-4324
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4325)
     pc-4325
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4326
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4327)
     pc-4327
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4328)
     pc-4328
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4329)
     pc-4329
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4330)
     pc-4330
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4331
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4332)
     pc-4332
       (cl:setf pc 4334) (cl:go pc-4334)
     pc-4333
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4334)
     pc-4334
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 4335)
     pc-4335
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4336)
     pc-4336
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4337)
     pc-4337
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4338)
     pc-4338
       (cl:when flag (cl:setf pc 4353) (cl:go pc-4353))
     pc-4339
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4340)
     pc-4340
       (cl:when flag (cl:setf pc 4346) (cl:go pc-4346))
     pc-4341
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4342)
     pc-4342
       (cl:when flag (cl:setf pc 4351) (cl:go pc-4351))
     pc-4343
       (cl:setf continue (cl:cons '|compilation-unit| 4354))
       (cl:setf pc 4344)
     pc-4344
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4345)
     pc-4345
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4346
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4347)
     pc-4347
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4348)
     pc-4348
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4349)
     pc-4349
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4350)
     pc-4350
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4351
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4352)
     pc-4352
       (cl:setf pc 4354) (cl:go pc-4354)
     pc-4353
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4354)
     pc-4354
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 4355)
     pc-4355
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4356)
     pc-4356
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4357)
     pc-4357
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4358)
     pc-4358
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4359)
     pc-4359
       (cl:when flag (cl:setf pc 4373) (cl:go pc-4373))
     pc-4360
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4361)
     pc-4361
       (cl:when flag (cl:setf pc 4366) (cl:go pc-4366))
     pc-4362
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4363)
     pc-4363
       (cl:when flag (cl:setf pc 4371) (cl:go pc-4371))
     pc-4364
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4365)
     pc-4365
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4366
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4367)
     pc-4367
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4368)
     pc-4368
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4369)
     pc-4369
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4370)
     pc-4370
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4371
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4372)
     pc-4372
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4373
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4374)
     pc-4374
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4375
       (cl:push continue stack)
       (cl:setf pc 4376)
     pc-4376
       (cl:push proc stack)
       (cl:setf pc 4377)
     pc-4377
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 1 2 env))
       (cl:setf pc 4378)
     pc-4378
       (cl:push proc stack)
       (cl:setf pc 4379)
     pc-4379
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|ece-scheme-read| env))
       (cl:setf pc 4380)
     pc-4380
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 4381)
     pc-4381
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4382)
     pc-4382
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4383)
     pc-4383
       (cl:when flag (cl:setf pc 4398) (cl:go pc-4398))
     pc-4384
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4385)
     pc-4385
       (cl:when flag (cl:setf pc 4391) (cl:go pc-4391))
     pc-4386
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4387)
     pc-4387
       (cl:when flag (cl:setf pc 4396) (cl:go pc-4396))
     pc-4388
       (cl:setf continue (cl:cons '|compilation-unit| 4399))
       (cl:setf pc 4389)
     pc-4389
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4390)
     pc-4390
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4391
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4392)
     pc-4392
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4393)
     pc-4393
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4394)
     pc-4394
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4395)
     pc-4395
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4396
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4397)
     pc-4397
       (cl:setf pc 4399) (cl:go pc-4399)
     pc-4398
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4399)
     pc-4399
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4400)
     pc-4400
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4401)
     pc-4401
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4402)
     pc-4402
       (cl:when flag (cl:setf pc 4417) (cl:go pc-4417))
     pc-4403
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4404)
     pc-4404
       (cl:when flag (cl:setf pc 4410) (cl:go pc-4410))
     pc-4405
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4406)
     pc-4406
       (cl:when flag (cl:setf pc 4415) (cl:go pc-4415))
     pc-4407
       (cl:setf continue (cl:cons '|compilation-unit| 4418))
       (cl:setf pc 4408)
     pc-4408
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4409)
     pc-4409
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4410
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4411)
     pc-4411
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4412)
     pc-4412
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4413)
     pc-4413
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4414)
     pc-4414
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4415
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4416)
     pc-4416
       (cl:setf pc 4418) (cl:go pc-4418)
     pc-4417
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4418)
     pc-4418
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4419)
     pc-4419
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4420)
     pc-4420
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4421)
     pc-4421
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4422)
     pc-4422
       (cl:when flag (cl:setf pc 4436) (cl:go pc-4436))
     pc-4423
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4424)
     pc-4424
       (cl:when flag (cl:setf pc 4429) (cl:go pc-4429))
     pc-4425
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4426)
     pc-4426
       (cl:when flag (cl:setf pc 4434) (cl:go pc-4434))
     pc-4427
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4428)
     pc-4428
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4429
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4430)
     pc-4430
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4431)
     pc-4431
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4432)
     pc-4432
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4433)
     pc-4433
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4434
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4435)
     pc-4435
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4436
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4437)
     pc-4437
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4438
       (cl:funcall (get-operation '|lexical-set!|) 0 3 val env)
       (cl:setf pc 4439)
     pc-4439
       (cl:setf val val)
       (cl:setf pc 4440)
     pc-4440
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 4442 env))
       (cl:setf pc 4441)
     pc-4441
       (cl:setf pc 5159) (cl:go pc-5159)
     pc-4442
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 4443)
     pc-4443
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|result|) argl env 0))
       (cl:setf pc 4444)
     pc-4444
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 4446 env))
       (cl:setf pc 4445)
     pc-4445
       (cl:setf pc 5096) (cl:go pc-5096)
     pc-4446
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 4447)
     pc-4447
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|units|) argl env 0))
       (cl:setf pc 4448)
     pc-4448
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 4450 env))
       (cl:setf pc 4449)
     pc-4449
       (cl:setf pc 5033) (cl:go pc-5033)
     pc-4450
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 4451)
     pc-4451
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|macros-defined|) argl env 0))
       (cl:setf pc 4452)
     pc-4452
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 4454 env))
       (cl:setf pc 4453)
     pc-4453
       (cl:setf pc 4991) (cl:go pc-4991)
     pc-4454
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 4455)
     pc-4455
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|merged|) argl env 0))
       (cl:setf pc 4456)
     pc-4456
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 4458 env))
       (cl:setf pc 4457)
     pc-4457
       (cl:setf pc 4949) (cl:go pc-4949)
     pc-4458
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 4459)
     pc-4459
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|renamed|) argl env 0))
       (cl:setf pc 4460)
     pc-4460
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 4462 env))
       (cl:setf pc 4461)
     pc-4461
       (cl:setf pc 4907) (cl:go pc-4907)
     pc-4462
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 4463)
     pc-4463
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|extracted|) argl env 0))
       (cl:setf pc 4464)
     pc-4464
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 4466 env))
       (cl:setf pc 4465)
     pc-4465
       (cl:setf pc 4865) (cl:go pc-4865)
     pc-4466
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 4467)
     pc-4467
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|clean-instrs|) argl env 0))
       (cl:setf pc 4468)
     pc-4468
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 4470 env))
       (cl:setf pc 4469)
     pc-4469
       (cl:setf pc 4823) (cl:go pc-4823)
     pc-4470
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 4471)
     pc-4471
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|source-map-entries|) argl env 0))
       (cl:setf pc 4472)
     pc-4472
       (cl:push continue stack)
       (cl:setf pc 4473)
     pc-4473
       (cl:push env stack)
       (cl:setf pc 4474)
     pc-4474
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-string-to-port| env))
       (cl:setf pc 4475)
     pc-4475
       (cl:push proc stack)
       (cl:setf pc 4476)
     pc-4476
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 11 1 env))
       (cl:setf pc 4477)
     pc-4477
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4478)
     pc-4478
       (cl:push argl stack)
       (cl:setf pc 4479)
     pc-4479
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-to-string-flat| env))
       (cl:setf pc 4480)
     pc-4480
       (cl:push proc stack)
       (cl:setf pc 4481)
     pc-4481
       (cl:push env stack)
       (cl:setf pc 4482)
     pc-4482
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|null?| env))
       (cl:setf pc 4483)
     pc-4483
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4484)
     pc-4484
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4485)
     pc-4485
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4486)
     pc-4486
       (cl:when flag (cl:setf pc 4501) (cl:go pc-4501))
     pc-4487
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4488)
     pc-4488
       (cl:when flag (cl:setf pc 4494) (cl:go pc-4494))
     pc-4489
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4490)
     pc-4490
       (cl:when flag (cl:setf pc 4499) (cl:go pc-4499))
     pc-4491
       (cl:setf continue (cl:cons '|compilation-unit| 4502))
       (cl:setf pc 4492)
     pc-4492
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4493)
     pc-4493
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4494
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4495)
     pc-4495
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4496)
     pc-4496
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4497)
     pc-4497
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4498)
     pc-4498
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4499
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4500)
     pc-4500
       (cl:setf pc 4502) (cl:go pc-4502)
     pc-4501
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4502)
     pc-4502
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4503)
     pc-4503
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 4504)
     pc-4504
       (cl:when flag (cl:setf pc 4578) (cl:go pc-4578))
     pc-4505
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 4506)
     pc-4506
       (cl:push proc stack)
       (cl:setf pc 4507)
     pc-4507
       (cl:push env stack)
       (cl:setf pc 4508)
     pc-4508
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 4509)
     pc-4509
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 5 0 env))
       (cl:setf pc 4510)
     pc-4510
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4511)
     pc-4511
       (cl:setf val '|macros|)
       (cl:setf pc 4512)
     pc-4512
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4513)
     pc-4513
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4514)
     pc-4514
       (cl:when flag (cl:setf pc 4529) (cl:go pc-4529))
     pc-4515
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4516)
     pc-4516
       (cl:when flag (cl:setf pc 4522) (cl:go pc-4522))
     pc-4517
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4518)
     pc-4518
       (cl:when flag (cl:setf pc 4527) (cl:go pc-4527))
     pc-4519
       (cl:setf continue (cl:cons '|compilation-unit| 4530))
       (cl:setf pc 4520)
     pc-4520
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4521)
     pc-4521
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4522
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4523)
     pc-4523
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4524)
     pc-4524
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4525)
     pc-4525
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4526)
     pc-4526
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4527
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4528)
     pc-4528
       (cl:setf pc 4530) (cl:go pc-4530)
     pc-4529
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4530)
     pc-4530
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4531)
     pc-4531
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4532)
     pc-4532
       (cl:push argl stack)
       (cl:setf pc 4533)
     pc-4533
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 4534)
     pc-4534
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 10 0 env))
       (cl:setf pc 4535)
     pc-4535
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4536)
     pc-4536
       (cl:setf val '|space|)
       (cl:setf pc 4537)
     pc-4537
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4538)
     pc-4538
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4539)
     pc-4539
       (cl:when flag (cl:setf pc 4554) (cl:go pc-4554))
     pc-4540
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4541)
     pc-4541
       (cl:when flag (cl:setf pc 4547) (cl:go pc-4547))
     pc-4542
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4543)
     pc-4543
       (cl:when flag (cl:setf pc 4552) (cl:go pc-4552))
     pc-4544
       (cl:setf continue (cl:cons '|compilation-unit| 4555))
       (cl:setf pc 4545)
     pc-4545
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4546)
     pc-4546
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4547
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4548)
     pc-4548
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4549)
     pc-4549
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4550)
     pc-4550
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4551)
     pc-4551
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4552
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4553)
     pc-4553
       (cl:setf pc 4555) (cl:go pc-4555)
     pc-4554
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4555)
     pc-4555
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 4556)
     pc-4556
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4557)
     pc-4557
       (cl:setf val '|ecec-header|)
       (cl:setf pc 4558)
     pc-4558
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4559)
     pc-4559
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4560)
     pc-4560
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4561)
     pc-4561
       (cl:when flag (cl:setf pc 4576) (cl:go pc-4576))
     pc-4562
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4563)
     pc-4563
       (cl:when flag (cl:setf pc 4569) (cl:go pc-4569))
     pc-4564
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4565)
     pc-4565
       (cl:when flag (cl:setf pc 4574) (cl:go pc-4574))
     pc-4566
       (cl:setf continue (cl:cons '|compilation-unit| 4700))
       (cl:setf pc 4567)
     pc-4567
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4568)
     pc-4568
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4569
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4570)
     pc-4570
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4571)
     pc-4571
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4572)
     pc-4572
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4573)
     pc-4573
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4574
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4575)
     pc-4575
       (cl:setf pc 4700) (cl:go pc-4700)
     pc-4576
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4577)
     pc-4577
       (cl:setf pc 4700) (cl:go pc-4700)
     pc-4578
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 4579)
     pc-4579
       (cl:push proc stack)
       (cl:setf pc 4580)
     pc-4580
       (cl:push env stack)
       (cl:setf pc 4581)
     pc-4581
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 4582)
     pc-4582
       (cl:push proc stack)
       (cl:setf pc 4583)
     pc-4583
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cons| env))
       (cl:setf pc 4584)
     pc-4584
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4585)
     pc-4585
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4586)
     pc-4586
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 9 0 env))
       (cl:setf pc 4587)
     pc-4587
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4588)
     pc-4588
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4589)
     pc-4589
       (cl:when flag (cl:setf pc 4604) (cl:go pc-4604))
     pc-4590
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4591)
     pc-4591
       (cl:when flag (cl:setf pc 4597) (cl:go pc-4597))
     pc-4592
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4593)
     pc-4593
       (cl:when flag (cl:setf pc 4602) (cl:go pc-4602))
     pc-4594
       (cl:setf continue (cl:cons '|compilation-unit| 4605))
       (cl:setf pc 4595)
     pc-4595
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4596)
     pc-4596
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4597
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4598)
     pc-4598
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4599)
     pc-4599
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4600)
     pc-4600
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4601)
     pc-4601
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4602
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4603)
     pc-4603
       (cl:setf pc 4605) (cl:go pc-4605)
     pc-4604
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4605)
     pc-4605
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4606)
     pc-4606
       (cl:setf val '|source-map|)
       (cl:setf pc 4607)
     pc-4607
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4608)
     pc-4608
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4609)
     pc-4609
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4610)
     pc-4610
       (cl:when flag (cl:setf pc 4625) (cl:go pc-4625))
     pc-4611
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4612)
     pc-4612
       (cl:when flag (cl:setf pc 4618) (cl:go pc-4618))
     pc-4613
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4614)
     pc-4614
       (cl:when flag (cl:setf pc 4623) (cl:go pc-4623))
     pc-4615
       (cl:setf continue (cl:cons '|compilation-unit| 4626))
       (cl:setf pc 4616)
     pc-4616
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4617)
     pc-4617
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4618
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4619)
     pc-4619
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4620)
     pc-4620
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4621)
     pc-4621
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4622)
     pc-4622
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4623
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4624)
     pc-4624
       (cl:setf pc 4626) (cl:go pc-4626)
     pc-4625
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4626)
     pc-4626
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4627)
     pc-4627
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4628)
     pc-4628
       (cl:push env stack)
       (cl:setf pc 4629)
     pc-4629
       (cl:push argl stack)
       (cl:setf pc 4630)
     pc-4630
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 4631)
     pc-4631
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 5 0 env))
       (cl:setf pc 4632)
     pc-4632
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4633)
     pc-4633
       (cl:setf val '|macros|)
       (cl:setf pc 4634)
     pc-4634
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4635)
     pc-4635
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4636)
     pc-4636
       (cl:when flag (cl:setf pc 4651) (cl:go pc-4651))
     pc-4637
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4638)
     pc-4638
       (cl:when flag (cl:setf pc 4644) (cl:go pc-4644))
     pc-4639
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4640)
     pc-4640
       (cl:when flag (cl:setf pc 4649) (cl:go pc-4649))
     pc-4641
       (cl:setf continue (cl:cons '|compilation-unit| 4652))
       (cl:setf pc 4642)
     pc-4642
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4643)
     pc-4643
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4644
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4645)
     pc-4645
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4646)
     pc-4646
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4647)
     pc-4647
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4648)
     pc-4648
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4649
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4650)
     pc-4650
       (cl:setf pc 4652) (cl:go pc-4652)
     pc-4651
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4652)
     pc-4652
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 4653)
     pc-4653
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4654)
     pc-4654
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4655)
     pc-4655
       (cl:push argl stack)
       (cl:setf pc 4656)
     pc-4656
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 4657)
     pc-4657
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 10 0 env))
       (cl:setf pc 4658)
     pc-4658
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4659)
     pc-4659
       (cl:setf val '|space|)
       (cl:setf pc 4660)
     pc-4660
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4661)
     pc-4661
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4662)
     pc-4662
       (cl:when flag (cl:setf pc 4677) (cl:go pc-4677))
     pc-4663
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4664)
     pc-4664
       (cl:when flag (cl:setf pc 4670) (cl:go pc-4670))
     pc-4665
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4666)
     pc-4666
       (cl:when flag (cl:setf pc 4675) (cl:go pc-4675))
     pc-4667
       (cl:setf continue (cl:cons '|compilation-unit| 4678))
       (cl:setf pc 4668)
     pc-4668
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4669)
     pc-4669
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4670
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4671)
     pc-4671
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4672)
     pc-4672
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4673)
     pc-4673
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4674)
     pc-4674
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4675
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4676)
     pc-4676
       (cl:setf pc 4678) (cl:go pc-4678)
     pc-4677
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4678)
     pc-4678
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 4679)
     pc-4679
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4680)
     pc-4680
       (cl:setf val '|ecec-header|)
       (cl:setf pc 4681)
     pc-4681
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4682)
     pc-4682
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4683)
     pc-4683
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4684)
     pc-4684
       (cl:when flag (cl:setf pc 4699) (cl:go pc-4699))
     pc-4685
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4686)
     pc-4686
       (cl:when flag (cl:setf pc 4692) (cl:go pc-4692))
     pc-4687
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4688)
     pc-4688
       (cl:when flag (cl:setf pc 4697) (cl:go pc-4697))
     pc-4689
       (cl:setf continue (cl:cons '|compilation-unit| 4700))
       (cl:setf pc 4690)
     pc-4690
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4691)
     pc-4691
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4692
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4693)
     pc-4693
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4694)
     pc-4694
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4695)
     pc-4695
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4696)
     pc-4696
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4697
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4698)
     pc-4698
       (cl:setf pc 4700) (cl:go pc-4700)
     pc-4699
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4700)
     pc-4700
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4701)
     pc-4701
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4702)
     pc-4702
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4703)
     pc-4703
       (cl:when flag (cl:setf pc 4718) (cl:go pc-4718))
     pc-4704
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4705)
     pc-4705
       (cl:when flag (cl:setf pc 4711) (cl:go pc-4711))
     pc-4706
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4707)
     pc-4707
       (cl:when flag (cl:setf pc 4716) (cl:go pc-4716))
     pc-4708
       (cl:setf continue (cl:cons '|compilation-unit| 4719))
       (cl:setf pc 4709)
     pc-4709
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4710)
     pc-4710
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4711
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4712)
     pc-4712
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4713)
     pc-4713
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4714)
     pc-4714
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4715)
     pc-4715
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4716
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4717)
     pc-4717
       (cl:setf pc 4719) (cl:go pc-4719)
     pc-4718
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4719)
     pc-4719
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 4720)
     pc-4720
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4721)
     pc-4721
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4722)
     pc-4722
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4723)
     pc-4723
       (cl:when flag (cl:setf pc 4738) (cl:go pc-4738))
     pc-4724
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4725)
     pc-4725
       (cl:when flag (cl:setf pc 4731) (cl:go pc-4731))
     pc-4726
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4727)
     pc-4727
       (cl:when flag (cl:setf pc 4736) (cl:go pc-4736))
     pc-4728
       (cl:setf continue (cl:cons '|compilation-unit| 4739))
       (cl:setf pc 4729)
     pc-4729
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4730)
     pc-4730
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4731
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4732)
     pc-4732
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4733)
     pc-4733
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4734)
     pc-4734
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4735)
     pc-4735
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4736
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4737)
     pc-4737
       (cl:setf pc 4739) (cl:go pc-4739)
     pc-4738
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4739)
     pc-4739
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4740)
     pc-4740
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4741)
     pc-4741
       (cl:push continue stack)
       (cl:setf pc 4742)
     pc-4742
       (cl:push env stack)
       (cl:setf pc 4743)
     pc-4743
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-char| env))
       (cl:setf pc 4744)
     pc-4744
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 11 1 env))
       (cl:setf pc 4745)
     pc-4745
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4746)
     pc-4746
       (cl:setf val #\Newline)
       (cl:setf pc 4747)
     pc-4747
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4748)
     pc-4748
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4749)
     pc-4749
       (cl:when flag (cl:setf pc 4764) (cl:go pc-4764))
     pc-4750
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4751)
     pc-4751
       (cl:when flag (cl:setf pc 4757) (cl:go pc-4757))
     pc-4752
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4753)
     pc-4753
       (cl:when flag (cl:setf pc 4762) (cl:go pc-4762))
     pc-4754
       (cl:setf continue (cl:cons '|compilation-unit| 4765))
       (cl:setf pc 4755)
     pc-4755
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4756)
     pc-4756
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4757
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4758)
     pc-4758
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4759)
     pc-4759
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4760)
     pc-4760
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4761)
     pc-4761
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4762
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4763)
     pc-4763
       (cl:setf pc 4765) (cl:go pc-4765)
     pc-4764
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4765)
     pc-4765
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4766)
     pc-4766
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4767)
     pc-4767
       (cl:push continue stack)
       (cl:setf pc 4768)
     pc-4768
       (cl:push env stack)
       (cl:setf pc 4769)
     pc-4769
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|write-flat-instructions| env))
       (cl:setf pc 4770)
     pc-4770
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 11 1 env))
       (cl:setf pc 4771)
     pc-4771
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4772)
     pc-4772
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 4773)
     pc-4773
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 4774)
     pc-4774
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4775)
     pc-4775
       (cl:when flag (cl:setf pc 4790) (cl:go pc-4790))
     pc-4776
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4777)
     pc-4777
       (cl:when flag (cl:setf pc 4783) (cl:go pc-4783))
     pc-4778
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4779)
     pc-4779
       (cl:when flag (cl:setf pc 4788) (cl:go pc-4788))
     pc-4780
       (cl:setf continue (cl:cons '|compilation-unit| 4791))
       (cl:setf pc 4781)
     pc-4781
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4782)
     pc-4782
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4783
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4784)
     pc-4784
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4785)
     pc-4785
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4786)
     pc-4786
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4787)
     pc-4787
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4788
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4789)
     pc-4789
       (cl:setf pc 4791) (cl:go pc-4791)
     pc-4790
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4791)
     pc-4791
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4792)
     pc-4792
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4793)
     pc-4793
       (cl:push continue stack)
       (cl:setf pc 4794)
     pc-4794
       (cl:push env stack)
       (cl:setf pc 4795)
     pc-4795
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%make-hash-table| env))
       (cl:setf pc 4796)
     pc-4796
       (cl:setf argl cl:nil)
       (cl:setf pc 4797)
     pc-4797
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4798)
     pc-4798
       (cl:when flag (cl:setf pc 4813) (cl:go pc-4813))
     pc-4799
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4800)
     pc-4800
       (cl:when flag (cl:setf pc 4806) (cl:go pc-4806))
     pc-4801
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4802)
     pc-4802
       (cl:when flag (cl:setf pc 4811) (cl:go pc-4811))
     pc-4803
       (cl:setf continue (cl:cons '|compilation-unit| 4814))
       (cl:setf pc 4804)
     pc-4804
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4805)
     pc-4805
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4806
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4807)
     pc-4807
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4808)
     pc-4808
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4809)
     pc-4809
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4810)
     pc-4810
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4811
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4812)
     pc-4812
       (cl:setf pc 4814) (cl:go pc-4814)
     pc-4813
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4814)
     pc-4814
       (cl:setf env (cl:pop stack))
       (cl:setf pc 4815)
     pc-4815
       (cl:funcall (get-operation '|set-variable-value!|) '|*source-locations*| val env)
       (cl:setf pc 4816)
     pc-4816
       (cl:setf val val)
       (cl:setf pc 4817)
     pc-4817
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4818)
     pc-4818
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 4819)
     pc-4819
       (cl:funcall (get-operation '|set-variable-value!|) '|*source-file-name*| val env)
       (cl:setf pc 4820)
     pc-4820
       (cl:setf val val)
       (cl:setf pc 4821)
     pc-4821
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 10 0 env))
       (cl:setf pc 4822)
     pc-4822
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4823
       (cl:push continue stack)
       (cl:setf pc 4824)
     pc-4824
       (cl:push proc stack)
       (cl:setf pc 4825)
     pc-4825
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 4826)
     pc-4826
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 4827)
     pc-4827
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4828)
     pc-4828
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4829)
     pc-4829
       (cl:when flag (cl:setf pc 4844) (cl:go pc-4844))
     pc-4830
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4831)
     pc-4831
       (cl:when flag (cl:setf pc 4837) (cl:go pc-4837))
     pc-4832
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4833)
     pc-4833
       (cl:when flag (cl:setf pc 4842) (cl:go pc-4842))
     pc-4834
       (cl:setf continue (cl:cons '|compilation-unit| 4845))
       (cl:setf pc 4835)
     pc-4835
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4836)
     pc-4836
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4837
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4838)
     pc-4838
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4839)
     pc-4839
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4840)
     pc-4840
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4841)
     pc-4841
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4842
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4843)
     pc-4843
       (cl:setf pc 4845) (cl:go pc-4845)
     pc-4844
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4845)
     pc-4845
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4846)
     pc-4846
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4847)
     pc-4847
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4848)
     pc-4848
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4849)
     pc-4849
       (cl:when flag (cl:setf pc 4863) (cl:go pc-4863))
     pc-4850
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4851)
     pc-4851
       (cl:when flag (cl:setf pc 4856) (cl:go pc-4856))
     pc-4852
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4853)
     pc-4853
       (cl:when flag (cl:setf pc 4861) (cl:go pc-4861))
     pc-4854
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4855)
     pc-4855
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4856
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4857)
     pc-4857
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4858)
     pc-4858
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4859)
     pc-4859
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4860)
     pc-4860
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4861
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4862)
     pc-4862
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4863
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4864)
     pc-4864
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4865
       (cl:push continue stack)
       (cl:setf pc 4866)
     pc-4866
       (cl:push proc stack)
       (cl:setf pc 4867)
     pc-4867
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 4868)
     pc-4868
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4869)
     pc-4869
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4870)
     pc-4870
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4871)
     pc-4871
       (cl:when flag (cl:setf pc 4886) (cl:go pc-4886))
     pc-4872
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4873)
     pc-4873
       (cl:when flag (cl:setf pc 4879) (cl:go pc-4879))
     pc-4874
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4875)
     pc-4875
       (cl:when flag (cl:setf pc 4884) (cl:go pc-4884))
     pc-4876
       (cl:setf continue (cl:cons '|compilation-unit| 4887))
       (cl:setf pc 4877)
     pc-4877
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4878)
     pc-4878
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4879
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4880)
     pc-4880
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4881)
     pc-4881
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4882)
     pc-4882
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4883)
     pc-4883
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4884
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4885)
     pc-4885
       (cl:setf pc 4887) (cl:go pc-4887)
     pc-4886
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4887)
     pc-4887
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4888)
     pc-4888
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4889)
     pc-4889
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4890)
     pc-4890
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4891)
     pc-4891
       (cl:when flag (cl:setf pc 4905) (cl:go pc-4905))
     pc-4892
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4893)
     pc-4893
       (cl:when flag (cl:setf pc 4898) (cl:go pc-4898))
     pc-4894
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4895)
     pc-4895
       (cl:when flag (cl:setf pc 4903) (cl:go pc-4903))
     pc-4896
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4897)
     pc-4897
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4898
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4899)
     pc-4899
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4900)
     pc-4900
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4901)
     pc-4901
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4902)
     pc-4902
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4903
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4904)
     pc-4904
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4905
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4906)
     pc-4906
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4907
       (cl:push continue stack)
       (cl:setf pc 4908)
     pc-4908
       (cl:push proc stack)
       (cl:setf pc 4909)
     pc-4909
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|extract-source-map| env))
       (cl:setf pc 4910)
     pc-4910
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4911)
     pc-4911
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4912)
     pc-4912
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4913)
     pc-4913
       (cl:when flag (cl:setf pc 4928) (cl:go pc-4928))
     pc-4914
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4915)
     pc-4915
       (cl:when flag (cl:setf pc 4921) (cl:go pc-4921))
     pc-4916
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4917)
     pc-4917
       (cl:when flag (cl:setf pc 4926) (cl:go pc-4926))
     pc-4918
       (cl:setf continue (cl:cons '|compilation-unit| 4929))
       (cl:setf pc 4919)
     pc-4919
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4920)
     pc-4920
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4921
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4922)
     pc-4922
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4923)
     pc-4923
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4924)
     pc-4924
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4925)
     pc-4925
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4926
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4927)
     pc-4927
       (cl:setf pc 4929) (cl:go pc-4929)
     pc-4928
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4929)
     pc-4929
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4930)
     pc-4930
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4931)
     pc-4931
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4932)
     pc-4932
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4933)
     pc-4933
       (cl:when flag (cl:setf pc 4947) (cl:go pc-4947))
     pc-4934
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4935)
     pc-4935
       (cl:when flag (cl:setf pc 4940) (cl:go pc-4940))
     pc-4936
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4937)
     pc-4937
       (cl:when flag (cl:setf pc 4945) (cl:go pc-4945))
     pc-4938
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4939)
     pc-4939
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4940
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4941)
     pc-4941
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4942)
     pc-4942
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4943)
     pc-4943
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4944)
     pc-4944
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4945
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4946)
     pc-4946
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4947
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4948)
     pc-4948
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4949
       (cl:push continue stack)
       (cl:setf pc 4950)
     pc-4950
       (cl:push proc stack)
       (cl:setf pc 4951)
     pc-4951
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|rename-labels| env))
       (cl:setf pc 4952)
     pc-4952
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 4953)
     pc-4953
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4954)
     pc-4954
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4955)
     pc-4955
       (cl:when flag (cl:setf pc 4970) (cl:go pc-4970))
     pc-4956
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4957)
     pc-4957
       (cl:when flag (cl:setf pc 4963) (cl:go pc-4963))
     pc-4958
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4959)
     pc-4959
       (cl:when flag (cl:setf pc 4968) (cl:go pc-4968))
     pc-4960
       (cl:setf continue (cl:cons '|compilation-unit| 4971))
       (cl:setf pc 4961)
     pc-4961
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4962)
     pc-4962
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4963
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4964)
     pc-4964
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4965)
     pc-4965
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4966)
     pc-4966
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4967)
     pc-4967
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4968
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4969)
     pc-4969
       (cl:setf pc 4971) (cl:go pc-4971)
     pc-4970
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4971)
     pc-4971
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4972)
     pc-4972
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 4973)
     pc-4973
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 4974)
     pc-4974
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4975)
     pc-4975
       (cl:when flag (cl:setf pc 4989) (cl:go pc-4989))
     pc-4976
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4977)
     pc-4977
       (cl:when flag (cl:setf pc 4982) (cl:go pc-4982))
     pc-4978
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 4979)
     pc-4979
       (cl:when flag (cl:setf pc 4987) (cl:go pc-4987))
     pc-4980
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 4981)
     pc-4981
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4982
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 4983)
     pc-4983
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 4984)
     pc-4984
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 4985)
     pc-4985
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 4986)
     pc-4986
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4987
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 4988)
     pc-4988
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4989
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 4990)
     pc-4990
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-4991
       (cl:push continue stack)
       (cl:setf pc 4992)
     pc-4992
       (cl:push proc stack)
       (cl:setf pc 4993)
     pc-4993
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|merge-instruction-lists| env))
       (cl:setf pc 4994)
     pc-4994
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 4995)
     pc-4995
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 4996)
     pc-4996
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 4997)
     pc-4997
       (cl:when flag (cl:setf pc 5012) (cl:go pc-5012))
     pc-4998
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 4999)
     pc-4999
       (cl:when flag (cl:setf pc 5005) (cl:go pc-5005))
     pc-5000
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5001)
     pc-5001
       (cl:when flag (cl:setf pc 5010) (cl:go pc-5010))
     pc-5002
       (cl:setf continue (cl:cons '|compilation-unit| 5013))
       (cl:setf pc 5003)
     pc-5003
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5004)
     pc-5004
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5005
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5006)
     pc-5006
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5007)
     pc-5007
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5008)
     pc-5008
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5009)
     pc-5009
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5010
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5011)
     pc-5011
       (cl:setf pc 5013) (cl:go pc-5013)
     pc-5012
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5013)
     pc-5013
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5014)
     pc-5014
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5015)
     pc-5015
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5016)
     pc-5016
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5017)
     pc-5017
       (cl:when flag (cl:setf pc 5031) (cl:go pc-5031))
     pc-5018
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5019)
     pc-5019
       (cl:when flag (cl:setf pc 5024) (cl:go pc-5024))
     pc-5020
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5021)
     pc-5021
       (cl:when flag (cl:setf pc 5029) (cl:go pc-5029))
     pc-5022
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5023)
     pc-5023
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5024
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5025)
     pc-5025
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5026)
     pc-5026
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5027)
     pc-5027
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5028)
     pc-5028
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5029
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5030)
     pc-5030
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5031
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5032)
     pc-5032
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5033
       (cl:push continue stack)
       (cl:setf pc 5034)
     pc-5034
       (cl:push proc stack)
       (cl:setf pc 5035)
     pc-5035
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|reverse| env))
       (cl:setf pc 5036)
     pc-5036
       (cl:push proc stack)
       (cl:setf pc 5037)
     pc-5037
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 5038)
     pc-5038
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 5039)
     pc-5039
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5040)
     pc-5040
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5041)
     pc-5041
       (cl:when flag (cl:setf pc 5056) (cl:go pc-5056))
     pc-5042
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5043)
     pc-5043
       (cl:when flag (cl:setf pc 5049) (cl:go pc-5049))
     pc-5044
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5045)
     pc-5045
       (cl:when flag (cl:setf pc 5054) (cl:go pc-5054))
     pc-5046
       (cl:setf continue (cl:cons '|compilation-unit| 5057))
       (cl:setf pc 5047)
     pc-5047
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5048)
     pc-5048
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5049
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5050)
     pc-5050
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5051)
     pc-5051
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5052)
     pc-5052
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5053)
     pc-5053
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5054
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5055)
     pc-5055
       (cl:setf pc 5057) (cl:go pc-5057)
     pc-5056
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5057)
     pc-5057
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5058)
     pc-5058
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5059)
     pc-5059
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5060)
     pc-5060
       (cl:when flag (cl:setf pc 5075) (cl:go pc-5075))
     pc-5061
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5062)
     pc-5062
       (cl:when flag (cl:setf pc 5068) (cl:go pc-5068))
     pc-5063
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5064)
     pc-5064
       (cl:when flag (cl:setf pc 5073) (cl:go pc-5073))
     pc-5065
       (cl:setf continue (cl:cons '|compilation-unit| 5076))
       (cl:setf pc 5066)
     pc-5066
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5067)
     pc-5067
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5068
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5069)
     pc-5069
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5070)
     pc-5070
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5071)
     pc-5071
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5072)
     pc-5072
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5073
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5074)
     pc-5074
       (cl:setf pc 5076) (cl:go pc-5076)
     pc-5075
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5076)
     pc-5076
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5077)
     pc-5077
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5078)
     pc-5078
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5079)
     pc-5079
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5080)
     pc-5080
       (cl:when flag (cl:setf pc 5094) (cl:go pc-5094))
     pc-5081
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5082)
     pc-5082
       (cl:when flag (cl:setf pc 5087) (cl:go pc-5087))
     pc-5083
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5084)
     pc-5084
       (cl:when flag (cl:setf pc 5092) (cl:go pc-5092))
     pc-5085
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5086)
     pc-5086
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5087
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5088)
     pc-5088
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5089)
     pc-5089
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5090)
     pc-5090
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5091)
     pc-5091
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5092
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5093)
     pc-5093
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5094
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5095)
     pc-5095
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5096
       (cl:push continue stack)
       (cl:setf pc 5097)
     pc-5097
       (cl:push proc stack)
       (cl:setf pc 5098)
     pc-5098
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|reverse| env))
       (cl:setf pc 5099)
     pc-5099
       (cl:push proc stack)
       (cl:setf pc 5100)
     pc-5100
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 5101)
     pc-5101
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5102)
     pc-5102
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5103)
     pc-5103
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5104)
     pc-5104
       (cl:when flag (cl:setf pc 5119) (cl:go pc-5119))
     pc-5105
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5106)
     pc-5106
       (cl:when flag (cl:setf pc 5112) (cl:go pc-5112))
     pc-5107
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5108)
     pc-5108
       (cl:when flag (cl:setf pc 5117) (cl:go pc-5117))
     pc-5109
       (cl:setf continue (cl:cons '|compilation-unit| 5120))
       (cl:setf pc 5110)
     pc-5110
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5111)
     pc-5111
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5112
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5113)
     pc-5113
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5114)
     pc-5114
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5115)
     pc-5115
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5116)
     pc-5116
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5117
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5118)
     pc-5118
       (cl:setf pc 5120) (cl:go pc-5120)
     pc-5119
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5120)
     pc-5120
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5121)
     pc-5121
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5122)
     pc-5122
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5123)
     pc-5123
       (cl:when flag (cl:setf pc 5138) (cl:go pc-5138))
     pc-5124
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5125)
     pc-5125
       (cl:when flag (cl:setf pc 5131) (cl:go pc-5131))
     pc-5126
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5127)
     pc-5127
       (cl:when flag (cl:setf pc 5136) (cl:go pc-5136))
     pc-5128
       (cl:setf continue (cl:cons '|compilation-unit| 5139))
       (cl:setf pc 5129)
     pc-5129
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5130)
     pc-5130
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5131
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5132)
     pc-5132
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5133)
     pc-5133
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5134)
     pc-5134
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5135)
     pc-5135
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5136
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5137)
     pc-5137
       (cl:setf pc 5139) (cl:go pc-5139)
     pc-5138
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5139)
     pc-5139
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5140)
     pc-5140
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5141)
     pc-5141
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5142)
     pc-5142
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5143)
     pc-5143
       (cl:when flag (cl:setf pc 5157) (cl:go pc-5157))
     pc-5144
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5145)
     pc-5145
       (cl:when flag (cl:setf pc 5150) (cl:go pc-5150))
     pc-5146
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5147)
     pc-5147
       (cl:when flag (cl:setf pc 5155) (cl:go pc-5155))
     pc-5148
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5149)
     pc-5149
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5150
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5151)
     pc-5151
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5152)
     pc-5152
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5153)
     pc-5153
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5154)
     pc-5154
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5155
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5156)
     pc-5156
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5157
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5158)
     pc-5158
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5159
       (cl:push continue stack)
       (cl:setf pc 5160)
     pc-5160
       (cl:push proc stack)
       (cl:setf pc 5161)
     pc-5161
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 0 3 env))
       (cl:setf pc 5162)
     pc-5162
       (cl:setf val cl:nil)
       (cl:setf pc 5163)
     pc-5163
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5164)
     pc-5164
       (cl:setf val cl:nil)
       (cl:setf pc 5165)
     pc-5165
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 5166)
     pc-5166
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5167)
     pc-5167
       (cl:when flag (cl:setf pc 5182) (cl:go pc-5182))
     pc-5168
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5169)
     pc-5169
       (cl:when flag (cl:setf pc 5175) (cl:go pc-5175))
     pc-5170
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5171)
     pc-5171
       (cl:when flag (cl:setf pc 5180) (cl:go pc-5180))
     pc-5172
       (cl:setf continue (cl:cons '|compilation-unit| 5183))
       (cl:setf pc 5173)
     pc-5173
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5174)
     pc-5174
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5175
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5176)
     pc-5176
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5177)
     pc-5177
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5178)
     pc-5178
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5179)
     pc-5179
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5180
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5181)
     pc-5181
       (cl:setf pc 5183) (cl:go pc-5183)
     pc-5182
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5183)
     pc-5183
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5184)
     pc-5184
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5185)
     pc-5185
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5186)
     pc-5186
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5187)
     pc-5187
       (cl:when flag (cl:setf pc 5201) (cl:go pc-5201))
     pc-5188
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5189)
     pc-5189
       (cl:when flag (cl:setf pc 5194) (cl:go pc-5194))
     pc-5190
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5191)
     pc-5191
       (cl:when flag (cl:setf pc 5199) (cl:go pc-5199))
     pc-5192
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5193)
     pc-5193
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5194
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5195)
     pc-5195
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5196)
     pc-5196
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5197)
     pc-5197
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5198)
     pc-5198
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5199
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5200)
     pc-5200
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5201
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5202)
     pc-5202
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5203
       (cl:push continue stack)
       (cl:setf pc 5204)
     pc-5204
       (cl:push proc stack)
       (cl:setf pc 5205)
     pc-5205
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|open-input-file| env))
       (cl:setf pc 5206)
     pc-5206
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 5207)
     pc-5207
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5208)
     pc-5208
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5209)
     pc-5209
       (cl:when flag (cl:setf pc 5224) (cl:go pc-5224))
     pc-5210
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5211)
     pc-5211
       (cl:when flag (cl:setf pc 5217) (cl:go pc-5217))
     pc-5212
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5213)
     pc-5213
       (cl:when flag (cl:setf pc 5222) (cl:go pc-5222))
     pc-5214
       (cl:setf continue (cl:cons '|compilation-unit| 5225))
       (cl:setf pc 5215)
     pc-5215
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5216)
     pc-5216
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5217
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5218)
     pc-5218
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5219)
     pc-5219
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5220)
     pc-5220
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5221)
     pc-5221
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5222
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5223)
     pc-5223
       (cl:setf pc 5225) (cl:go pc-5225)
     pc-5224
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5225)
     pc-5225
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5226)
     pc-5226
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5227)
     pc-5227
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5228)
     pc-5228
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5229)
     pc-5229
       (cl:when flag (cl:setf pc 5243) (cl:go pc-5243))
     pc-5230
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5231)
     pc-5231
       (cl:when flag (cl:setf pc 5236) (cl:go pc-5236))
     pc-5232
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5233)
     pc-5233
       (cl:when flag (cl:setf pc 5241) (cl:go pc-5241))
     pc-5234
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5235)
     pc-5235
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5236
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5237)
     pc-5237
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5238)
     pc-5238
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5239)
     pc-5239
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5240)
     pc-5240
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5241
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5242)
     pc-5242
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5243
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5244)
     pc-5244
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5245
       (cl:push continue stack)
       (cl:setf pc 5246)
     pc-5246
       (cl:push proc stack)
       (cl:setf pc 5247)
     pc-5247
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|filename-basename| env))
       (cl:setf pc 5248)
     pc-5248
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 5249)
     pc-5249
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5250)
     pc-5250
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5251)
     pc-5251
       (cl:when flag (cl:setf pc 5266) (cl:go pc-5266))
     pc-5252
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5253)
     pc-5253
       (cl:when flag (cl:setf pc 5259) (cl:go pc-5259))
     pc-5254
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5255)
     pc-5255
       (cl:when flag (cl:setf pc 5264) (cl:go pc-5264))
     pc-5256
       (cl:setf continue (cl:cons '|compilation-unit| 5267))
       (cl:setf pc 5257)
     pc-5257
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5258)
     pc-5258
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5259
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5260)
     pc-5260
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5261)
     pc-5261
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5262)
     pc-5262
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5263)
     pc-5263
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5264
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5265)
     pc-5265
       (cl:setf pc 5267) (cl:go pc-5267)
     pc-5266
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5267)
     pc-5267
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5268)
     pc-5268
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5269)
     pc-5269
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5270)
     pc-5270
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5271)
     pc-5271
       (cl:when flag (cl:setf pc 5285) (cl:go pc-5285))
     pc-5272
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5273)
     pc-5273
       (cl:when flag (cl:setf pc 5278) (cl:go pc-5278))
     pc-5274
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5275)
     pc-5275
       (cl:when flag (cl:setf pc 5283) (cl:go pc-5283))
     pc-5276
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5277)
     pc-5277
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5278
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5279)
     pc-5279
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5280)
     pc-5280
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5281)
     pc-5281
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5282)
     pc-5282
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5283
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5284)
     pc-5284
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5285
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5286)
     pc-5286
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5287
       (cl:push continue stack)
       (cl:setf pc 5288)
     pc-5288
       (cl:push proc stack)
       (cl:setf pc 5289)
     pc-5289
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string->symbol| env))
       (cl:setf pc 5290)
     pc-5290
       (cl:push proc stack)
       (cl:setf pc 5291)
     pc-5291
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|filename-strip-extension| env))
       (cl:setf pc 5292)
     pc-5292
       (cl:push proc stack)
       (cl:setf pc 5293)
     pc-5293
       (cl:setf val ".scm")
       (cl:setf pc 5294)
     pc-5294
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5295)
     pc-5295
       (cl:push argl stack)
       (cl:setf pc 5296)
     pc-5296
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|filename-basename| env))
       (cl:setf pc 5297)
     pc-5297
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5298)
     pc-5298
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5299)
     pc-5299
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5300)
     pc-5300
       (cl:when flag (cl:setf pc 5315) (cl:go pc-5315))
     pc-5301
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5302)
     pc-5302
       (cl:when flag (cl:setf pc 5308) (cl:go pc-5308))
     pc-5303
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5304)
     pc-5304
       (cl:when flag (cl:setf pc 5313) (cl:go pc-5313))
     pc-5305
       (cl:setf continue (cl:cons '|compilation-unit| 5316))
       (cl:setf pc 5306)
     pc-5306
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5307)
     pc-5307
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5308
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5309)
     pc-5309
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5310)
     pc-5310
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5311)
     pc-5311
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5312)
     pc-5312
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5313
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5314)
     pc-5314
       (cl:setf pc 5316) (cl:go pc-5316)
     pc-5315
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5316)
     pc-5316
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 5317)
     pc-5317
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 5318)
     pc-5318
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5319)
     pc-5319
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5320)
     pc-5320
       (cl:when flag (cl:setf pc 5335) (cl:go pc-5335))
     pc-5321
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5322)
     pc-5322
       (cl:when flag (cl:setf pc 5328) (cl:go pc-5328))
     pc-5323
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5324)
     pc-5324
       (cl:when flag (cl:setf pc 5333) (cl:go pc-5333))
     pc-5325
       (cl:setf continue (cl:cons '|compilation-unit| 5336))
       (cl:setf pc 5326)
     pc-5326
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5327)
     pc-5327
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5328
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5329)
     pc-5329
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5330)
     pc-5330
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5331)
     pc-5331
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5332)
     pc-5332
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5333
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5334)
     pc-5334
       (cl:setf pc 5336) (cl:go pc-5336)
     pc-5335
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5336)
     pc-5336
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5337)
     pc-5337
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5338)
     pc-5338
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5339)
     pc-5339
       (cl:when flag (cl:setf pc 5354) (cl:go pc-5354))
     pc-5340
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5341)
     pc-5341
       (cl:when flag (cl:setf pc 5347) (cl:go pc-5347))
     pc-5342
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5343)
     pc-5343
       (cl:when flag (cl:setf pc 5352) (cl:go pc-5352))
     pc-5344
       (cl:setf continue (cl:cons '|compilation-unit| 5355))
       (cl:setf pc 5345)
     pc-5345
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5346)
     pc-5346
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5347
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5348)
     pc-5348
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5349)
     pc-5349
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5350)
     pc-5350
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5351)
     pc-5351
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5352
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5353)
     pc-5353
       (cl:setf pc 5355) (cl:go pc-5355)
     pc-5354
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5355)
     pc-5355
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5356)
     pc-5356
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5357)
     pc-5357
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5358)
     pc-5358
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5359)
     pc-5359
       (cl:when flag (cl:setf pc 5373) (cl:go pc-5373))
     pc-5360
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5361)
     pc-5361
       (cl:when flag (cl:setf pc 5366) (cl:go pc-5366))
     pc-5362
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5363)
     pc-5363
       (cl:when flag (cl:setf pc 5371) (cl:go pc-5371))
     pc-5364
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5365)
     pc-5365
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5366
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5367)
     pc-5367
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5368)
     pc-5368
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5369)
     pc-5369
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5370)
     pc-5370
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5371
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5372)
     pc-5372
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5373
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5374)
     pc-5374
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5375
       (cl:funcall (get-operation '|define-variable!|) '|compile-file-to-port| val env)
       (cl:setf pc 5376)
     pc-5376
       (cl:setf val val)
       (cl:setf pc 5377)
     pc-5377
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 5378)
     pc-5378
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 5380 env))
       (cl:setf pc 5379)
     pc-5379
       (cl:setf pc 5554) (cl:go pc-5554)
     pc-5380
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5381)
     pc-5381
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|filename|) argl env 0))
       (cl:setf pc 5382)
     pc-5382
       (cl:setf val "Compile all forms in FILENAME, write compiled units to a .ecec file.
Emits an ecec-header with space name, macro list, and source-map,
followed by compiled units.
Returns the output filename.")
       (cl:setf pc 5383)
     pc-5383
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 5385 env))
       (cl:setf pc 5384)
     pc-5384
       (cl:setf pc 5485) (cl:go pc-5485)
     pc-5385
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5386)
     pc-5386
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|output-name|) argl env 0))
       (cl:setf pc 5387)
     pc-5387
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 5389 env))
       (cl:setf pc 5388)
     pc-5388
       (cl:setf pc 5443) (cl:go pc-5443)
     pc-5389
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5390)
     pc-5390
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|out|) argl env 0))
       (cl:setf pc 5391)
     pc-5391
       (cl:push continue stack)
       (cl:setf pc 5392)
     pc-5392
       (cl:push env stack)
       (cl:setf pc 5393)
     pc-5393
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|compile-file-to-port| env))
       (cl:setf pc 5394)
     pc-5394
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5395)
     pc-5395
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5396)
     pc-5396
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 5397)
     pc-5397
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 5398)
     pc-5398
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5399)
     pc-5399
       (cl:when flag (cl:setf pc 5414) (cl:go pc-5414))
     pc-5400
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5401)
     pc-5401
       (cl:when flag (cl:setf pc 5407) (cl:go pc-5407))
     pc-5402
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5403)
     pc-5403
       (cl:when flag (cl:setf pc 5412) (cl:go pc-5412))
     pc-5404
       (cl:setf continue (cl:cons '|compilation-unit| 5415))
       (cl:setf pc 5405)
     pc-5405
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5406)
     pc-5406
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5407
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5408)
     pc-5408
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5409)
     pc-5409
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5410)
     pc-5410
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5411)
     pc-5411
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5412
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5413)
     pc-5413
       (cl:setf pc 5415) (cl:go pc-5415)
     pc-5414
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5415)
     pc-5415
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5416)
     pc-5416
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5417)
     pc-5417
       (cl:push continue stack)
       (cl:setf pc 5418)
     pc-5418
       (cl:push env stack)
       (cl:setf pc 5419)
     pc-5419
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|close-output-port| env))
       (cl:setf pc 5420)
     pc-5420
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5421)
     pc-5421
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5422)
     pc-5422
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5423)
     pc-5423
       (cl:when flag (cl:setf pc 5438) (cl:go pc-5438))
     pc-5424
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5425)
     pc-5425
       (cl:when flag (cl:setf pc 5431) (cl:go pc-5431))
     pc-5426
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5427)
     pc-5427
       (cl:when flag (cl:setf pc 5436) (cl:go pc-5436))
     pc-5428
       (cl:setf continue (cl:cons '|compilation-unit| 5439))
       (cl:setf pc 5429)
     pc-5429
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5430)
     pc-5430
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5431
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5432)
     pc-5432
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5433)
     pc-5433
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5434)
     pc-5434
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5435)
     pc-5435
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5436
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5437)
     pc-5437
       (cl:setf pc 5439) (cl:go pc-5439)
     pc-5438
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5439)
     pc-5439
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5440)
     pc-5440
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5441)
     pc-5441
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 5442)
     pc-5442
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5443
       (cl:push continue stack)
       (cl:setf pc 5444)
     pc-5444
       (cl:push proc stack)
       (cl:setf pc 5445)
     pc-5445
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|open-output-file| env))
       (cl:setf pc 5446)
     pc-5446
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5447)
     pc-5447
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5448)
     pc-5448
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5449)
     pc-5449
       (cl:when flag (cl:setf pc 5464) (cl:go pc-5464))
     pc-5450
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5451)
     pc-5451
       (cl:when flag (cl:setf pc 5457) (cl:go pc-5457))
     pc-5452
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5453)
     pc-5453
       (cl:when flag (cl:setf pc 5462) (cl:go pc-5462))
     pc-5454
       (cl:setf continue (cl:cons '|compilation-unit| 5465))
       (cl:setf pc 5455)
     pc-5455
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5456)
     pc-5456
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5457
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5458)
     pc-5458
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5459)
     pc-5459
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5460)
     pc-5460
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5461)
     pc-5461
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5462
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5463)
     pc-5463
       (cl:setf pc 5465) (cl:go pc-5465)
     pc-5464
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5465)
     pc-5465
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5466)
     pc-5466
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5467)
     pc-5467
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5468)
     pc-5468
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5469)
     pc-5469
       (cl:when flag (cl:setf pc 5483) (cl:go pc-5483))
     pc-5470
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5471)
     pc-5471
       (cl:when flag (cl:setf pc 5476) (cl:go pc-5476))
     pc-5472
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5473)
     pc-5473
       (cl:when flag (cl:setf pc 5481) (cl:go pc-5481))
     pc-5474
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5475)
     pc-5475
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5476
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5477)
     pc-5477
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5478)
     pc-5478
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5479)
     pc-5479
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5480)
     pc-5480
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5481
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5482)
     pc-5482
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5483
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5484)
     pc-5484
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5485
       (cl:push continue stack)
       (cl:setf pc 5486)
     pc-5486
       (cl:push proc stack)
       (cl:setf pc 5487)
     pc-5487
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|string-append| env))
       (cl:setf pc 5488)
     pc-5488
       (cl:push proc stack)
       (cl:setf pc 5489)
     pc-5489
       (cl:setf val ".ecec")
       (cl:setf pc 5490)
     pc-5490
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5491)
     pc-5491
       (cl:push argl stack)
       (cl:setf pc 5492)
     pc-5492
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|filename-strip-extension| env))
       (cl:setf pc 5493)
     pc-5493
       (cl:setf val ".scm")
       (cl:setf pc 5494)
     pc-5494
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5495)
     pc-5495
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5496)
     pc-5496
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 5497)
     pc-5497
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5498)
     pc-5498
       (cl:when flag (cl:setf pc 5513) (cl:go pc-5513))
     pc-5499
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5500)
     pc-5500
       (cl:when flag (cl:setf pc 5506) (cl:go pc-5506))
     pc-5501
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5502)
     pc-5502
       (cl:when flag (cl:setf pc 5511) (cl:go pc-5511))
     pc-5503
       (cl:setf continue (cl:cons '|compilation-unit| 5514))
       (cl:setf pc 5504)
     pc-5504
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5505)
     pc-5505
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5506
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5507)
     pc-5507
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5508)
     pc-5508
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5509)
     pc-5509
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5510)
     pc-5510
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5511
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5512)
     pc-5512
       (cl:setf pc 5514) (cl:go pc-5514)
     pc-5513
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5514)
     pc-5514
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 5515)
     pc-5515
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 5516)
     pc-5516
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5517)
     pc-5517
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5518)
     pc-5518
       (cl:when flag (cl:setf pc 5533) (cl:go pc-5533))
     pc-5519
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5520)
     pc-5520
       (cl:when flag (cl:setf pc 5526) (cl:go pc-5526))
     pc-5521
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5522)
     pc-5522
       (cl:when flag (cl:setf pc 5531) (cl:go pc-5531))
     pc-5523
       (cl:setf continue (cl:cons '|compilation-unit| 5534))
       (cl:setf pc 5524)
     pc-5524
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5525)
     pc-5525
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5526
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5527)
     pc-5527
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5528)
     pc-5528
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5529)
     pc-5529
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5530)
     pc-5530
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5531
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5532)
     pc-5532
       (cl:setf pc 5534) (cl:go pc-5534)
     pc-5533
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5534)
     pc-5534
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5535)
     pc-5535
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5536)
     pc-5536
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5537)
     pc-5537
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5538)
     pc-5538
       (cl:when flag (cl:setf pc 5552) (cl:go pc-5552))
     pc-5539
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5540)
     pc-5540
       (cl:when flag (cl:setf pc 5545) (cl:go pc-5545))
     pc-5541
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5542)
     pc-5542
       (cl:when flag (cl:setf pc 5550) (cl:go pc-5550))
     pc-5543
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5544)
     pc-5544
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5545
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5546)
     pc-5546
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5547)
     pc-5547
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5548)
     pc-5548
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5549)
     pc-5549
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5550
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5551)
     pc-5551
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5552
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5553)
     pc-5553
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5554
       (cl:funcall (get-operation '|define-variable!|) '|compile-file| val env)
       (cl:setf pc 5555)
     pc-5555
       (cl:setf val val)
       (cl:setf pc 5556)
     pc-5556
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 5557)
     pc-5557
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 5559 env))
       (cl:setf pc 5558)
     pc-5558
       (cl:setf pc 5835) (cl:go pc-5835)
     pc-5559
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5560)
     pc-5560
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|filenames| |output-path|) argl env 0))
       (cl:setf pc 5561)
     pc-5561
       (cl:setf val "Compile a list of .scm FILENAMES into a single multi-space .ecec bundle
at OUTPUT-PATH. Each file is compiled to its own named space with its own
source-map. Returns OUTPUT-PATH.")
       (cl:setf pc 5562)
     pc-5562
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 5564 env))
       (cl:setf pc 5563)
     pc-5563
       (cl:setf pc 5793) (cl:go pc-5793)
     pc-5564
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5565)
     pc-5565
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|out|) argl env 0))
       (cl:setf pc 5566)
     pc-5566
       (cl:push continue stack)
       (cl:setf pc 5567)
     pc-5567
       (cl:push env stack)
       (cl:setf pc 5568)
     pc-5568
       (cl:push env stack)
       (cl:setf pc 5569)
     pc-5569
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 5571 env))
       (cl:setf pc 5570)
     pc-5570
       (cl:setf pc 5724) (cl:go pc-5724)
     pc-5571
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5572)
     pc-5572
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|loop|) argl env 0))
       (cl:setf pc 5573)
     pc-5573
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 5575 env))
       (cl:setf pc 5574)
     pc-5574
       (cl:setf pc 5582) (cl:go pc-5582)
     pc-5575
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5576)
     pc-5576
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|g183|) argl env 0))
       (cl:setf pc 5577)
     pc-5577
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5578)
     pc-5578
       (cl:funcall (get-operation '|lexical-set!|) 1 0 val env)
       (cl:setf pc 5579)
     pc-5579
       (cl:setf val val)
       (cl:setf pc 5580)
     pc-5580
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 5581)
     pc-5581
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5582
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 5584 env))
       (cl:setf pc 5583)
     pc-5583
       (cl:setf pc 5706) (cl:go pc-5706)
     pc-5584
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5585)
     pc-5585
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|files|) argl env 0))
       (cl:setf pc 5586)
     pc-5586
       (cl:push continue stack)
       (cl:setf pc 5587)
     pc-5587
       (cl:push env stack)
       (cl:setf pc 5588)
     pc-5588
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 5589)
     pc-5589
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5590)
     pc-5590
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5591)
     pc-5591
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5592)
     pc-5592
       (cl:when flag (cl:setf pc 5607) (cl:go pc-5607))
     pc-5593
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5594)
     pc-5594
       (cl:when flag (cl:setf pc 5600) (cl:go pc-5600))
     pc-5595
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5596)
     pc-5596
       (cl:when flag (cl:setf pc 5605) (cl:go pc-5605))
     pc-5597
       (cl:setf continue (cl:cons '|compilation-unit| 5608))
       (cl:setf pc 5598)
     pc-5598
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5599)
     pc-5599
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5600
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5601)
     pc-5601
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5602)
     pc-5602
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5603)
     pc-5603
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5604)
     pc-5604
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5605
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5606)
     pc-5606
       (cl:setf pc 5608) (cl:go pc-5608)
     pc-5607
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5608)
     pc-5608
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5609)
     pc-5609
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5610)
     pc-5610
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 5611)
     pc-5611
       (cl:when flag (cl:setf pc 5704) (cl:go pc-5704))
     pc-5612
       (cl:push continue stack)
       (cl:setf pc 5613)
     pc-5613
       (cl:push env stack)
       (cl:setf pc 5614)
     pc-5614
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|compile-file-to-port| env))
       (cl:setf pc 5615)
     pc-5615
       (cl:push proc stack)
       (cl:setf pc 5616)
     pc-5616
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 5617)
     pc-5617
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5618)
     pc-5618
       (cl:push argl stack)
       (cl:setf pc 5619)
     pc-5619
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 5620)
     pc-5620
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5621)
     pc-5621
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5622)
     pc-5622
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5623)
     pc-5623
       (cl:when flag (cl:setf pc 5638) (cl:go pc-5638))
     pc-5624
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5625)
     pc-5625
       (cl:when flag (cl:setf pc 5631) (cl:go pc-5631))
     pc-5626
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5627)
     pc-5627
       (cl:when flag (cl:setf pc 5636) (cl:go pc-5636))
     pc-5628
       (cl:setf continue (cl:cons '|compilation-unit| 5639))
       (cl:setf pc 5629)
     pc-5629
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5630)
     pc-5630
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5631
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5632)
     pc-5632
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5633)
     pc-5633
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5634)
     pc-5634
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5635)
     pc-5635
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5636
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5637)
     pc-5637
       (cl:setf pc 5639) (cl:go pc-5639)
     pc-5638
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5639)
     pc-5639
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 5640)
     pc-5640
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 5641)
     pc-5641
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5642)
     pc-5642
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5643)
     pc-5643
       (cl:when flag (cl:setf pc 5658) (cl:go pc-5658))
     pc-5644
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5645)
     pc-5645
       (cl:when flag (cl:setf pc 5651) (cl:go pc-5651))
     pc-5646
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5647)
     pc-5647
       (cl:when flag (cl:setf pc 5656) (cl:go pc-5656))
     pc-5648
       (cl:setf continue (cl:cons '|compilation-unit| 5659))
       (cl:setf pc 5649)
     pc-5649
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5650)
     pc-5650
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5651
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5652)
     pc-5652
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5653)
     pc-5653
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5654)
     pc-5654
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5655)
     pc-5655
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5656
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5657)
     pc-5657
       (cl:setf pc 5659) (cl:go pc-5659)
     pc-5658
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5659)
     pc-5659
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5660)
     pc-5660
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5661)
     pc-5661
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 5662)
     pc-5662
       (cl:push continue stack)
       (cl:setf pc 5663)
     pc-5663
       (cl:push proc stack)
       (cl:setf pc 5664)
     pc-5664
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 5665)
     pc-5665
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5666)
     pc-5666
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5667)
     pc-5667
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5668)
     pc-5668
       (cl:when flag (cl:setf pc 5683) (cl:go pc-5683))
     pc-5669
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5670)
     pc-5670
       (cl:when flag (cl:setf pc 5676) (cl:go pc-5676))
     pc-5671
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5672)
     pc-5672
       (cl:when flag (cl:setf pc 5681) (cl:go pc-5681))
     pc-5673
       (cl:setf continue (cl:cons '|compilation-unit| 5684))
       (cl:setf pc 5674)
     pc-5674
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5675)
     pc-5675
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5676
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5677)
     pc-5677
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5678)
     pc-5678
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5679)
     pc-5679
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5680)
     pc-5680
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5681
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5682)
     pc-5682
       (cl:setf pc 5684) (cl:go pc-5684)
     pc-5683
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5684)
     pc-5684
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5685)
     pc-5685
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5686)
     pc-5686
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5687)
     pc-5687
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5688)
     pc-5688
       (cl:when flag (cl:setf pc 5702) (cl:go pc-5702))
     pc-5689
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5690)
     pc-5690
       (cl:when flag (cl:setf pc 5695) (cl:go pc-5695))
     pc-5691
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5692)
     pc-5692
       (cl:when flag (cl:setf pc 5700) (cl:go pc-5700))
     pc-5693
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5694)
     pc-5694
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5695
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5696)
     pc-5696
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5697)
     pc-5697
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5698)
     pc-5698
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5699)
     pc-5699
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5700
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5701)
     pc-5701
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5702
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5703)
     pc-5703
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5704
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 5705)
     pc-5705
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5706
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5707)
     pc-5707
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5708)
     pc-5708
       (cl:when flag (cl:setf pc 5722) (cl:go pc-5722))
     pc-5709
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5710)
     pc-5710
       (cl:when flag (cl:setf pc 5715) (cl:go pc-5715))
     pc-5711
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5712)
     pc-5712
       (cl:when flag (cl:setf pc 5720) (cl:go pc-5720))
     pc-5713
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5714)
     pc-5714
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5715
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5716)
     pc-5716
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5717)
     pc-5717
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5718)
     pc-5718
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5719)
     pc-5719
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5720
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5721)
     pc-5721
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5722
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5723)
     pc-5723
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5724
       (cl:setf val cl:nil)
       (cl:setf pc 5725)
     pc-5725
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5726)
     pc-5726
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5727)
     pc-5727
       (cl:when flag (cl:setf pc 5744) (cl:go pc-5744))
     pc-5728
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5729)
     pc-5729
       (cl:when flag (cl:setf pc 5737) (cl:go pc-5737))
     pc-5730
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5731)
     pc-5731
       (cl:when flag (cl:setf pc 5742) (cl:go pc-5742))
     pc-5732
       (cl:setf continue (cl:cons '|compilation-unit| 5735))
       (cl:setf pc 5733)
     pc-5733
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5734)
     pc-5734
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5735
       (cl:setf proc val)
       (cl:setf pc 5736)
     pc-5736
       (cl:setf pc 5745) (cl:go pc-5745)
     pc-5737
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5738)
     pc-5738
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5739)
     pc-5739
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5740)
     pc-5740
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5741)
     pc-5741
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5742
       (cl:setf proc (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5743)
     pc-5743
       (cl:setf pc 5745) (cl:go pc-5745)
     pc-5744
       (cl:setf proc (cl:funcall (get-operation '|apply-primitive-procedure|) proc argl))
       (cl:setf pc 5745)
     pc-5745
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5746)
     pc-5746
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 5747)
     pc-5747
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5748)
     pc-5748
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5749)
     pc-5749
       (cl:when flag (cl:setf pc 5764) (cl:go pc-5764))
     pc-5750
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5751)
     pc-5751
       (cl:when flag (cl:setf pc 5757) (cl:go pc-5757))
     pc-5752
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5753)
     pc-5753
       (cl:when flag (cl:setf pc 5762) (cl:go pc-5762))
     pc-5754
       (cl:setf continue (cl:cons '|compilation-unit| 5765))
       (cl:setf pc 5755)
     pc-5755
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5756)
     pc-5756
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5757
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5758)
     pc-5758
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5759)
     pc-5759
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5760)
     pc-5760
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5761)
     pc-5761
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5762
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5763)
     pc-5763
       (cl:setf pc 5765) (cl:go pc-5765)
     pc-5764
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5765)
     pc-5765
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5766)
     pc-5766
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5767)
     pc-5767
       (cl:push continue stack)
       (cl:setf pc 5768)
     pc-5768
       (cl:push env stack)
       (cl:setf pc 5769)
     pc-5769
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|close-output-port| env))
       (cl:setf pc 5770)
     pc-5770
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5771)
     pc-5771
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5772)
     pc-5772
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5773)
     pc-5773
       (cl:when flag (cl:setf pc 5788) (cl:go pc-5788))
     pc-5774
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5775)
     pc-5775
       (cl:when flag (cl:setf pc 5781) (cl:go pc-5781))
     pc-5776
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5777)
     pc-5777
       (cl:when flag (cl:setf pc 5786) (cl:go pc-5786))
     pc-5778
       (cl:setf continue (cl:cons '|compilation-unit| 5789))
       (cl:setf pc 5779)
     pc-5779
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5780)
     pc-5780
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5781
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5782)
     pc-5782
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5783)
     pc-5783
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5784)
     pc-5784
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5785)
     pc-5785
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5786
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5787)
     pc-5787
       (cl:setf pc 5789) (cl:go pc-5789)
     pc-5788
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5789)
     pc-5789
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5790)
     pc-5790
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5791)
     pc-5791
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 5792)
     pc-5792
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5793
       (cl:push continue stack)
       (cl:setf pc 5794)
     pc-5794
       (cl:push proc stack)
       (cl:setf pc 5795)
     pc-5795
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|open-output-file| env))
       (cl:setf pc 5796)
     pc-5796
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 5797)
     pc-5797
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5798)
     pc-5798
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5799)
     pc-5799
       (cl:when flag (cl:setf pc 5814) (cl:go pc-5814))
     pc-5800
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5801)
     pc-5801
       (cl:when flag (cl:setf pc 5807) (cl:go pc-5807))
     pc-5802
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5803)
     pc-5803
       (cl:when flag (cl:setf pc 5812) (cl:go pc-5812))
     pc-5804
       (cl:setf continue (cl:cons '|compilation-unit| 5815))
       (cl:setf pc 5805)
     pc-5805
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5806)
     pc-5806
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5807
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5808)
     pc-5808
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5809)
     pc-5809
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5810)
     pc-5810
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5811)
     pc-5811
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5812
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5813)
     pc-5813
       (cl:setf pc 5815) (cl:go pc-5815)
     pc-5814
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5815)
     pc-5815
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5816)
     pc-5816
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5817)
     pc-5817
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5818)
     pc-5818
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5819)
     pc-5819
       (cl:when flag (cl:setf pc 5833) (cl:go pc-5833))
     pc-5820
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5821)
     pc-5821
       (cl:when flag (cl:setf pc 5826) (cl:go pc-5826))
     pc-5822
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5823)
     pc-5823
       (cl:when flag (cl:setf pc 5831) (cl:go pc-5831))
     pc-5824
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5825)
     pc-5825
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5826
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5827)
     pc-5827
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5828)
     pc-5828
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5829)
     pc-5829
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5830)
     pc-5830
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5831
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5832)
     pc-5832
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5833
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5834)
     pc-5834
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5835
       (cl:funcall (get-operation '|define-variable!|) '|compile-system| val env)
       (cl:setf pc 5836)
     pc-5836
       (cl:setf val val)
       (cl:setf pc 5837)
     pc-5837
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 5838)
     pc-5838
       (cl:push env stack)
       (cl:setf pc 5839)
     pc-5839
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%make-hash-table| env))
       (cl:setf pc 5840)
     pc-5840
       (cl:setf argl cl:nil)
       (cl:setf pc 5841)
     pc-5841
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5842)
     pc-5842
       (cl:when flag (cl:setf pc 5857) (cl:go pc-5857))
     pc-5843
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5844)
     pc-5844
       (cl:when flag (cl:setf pc 5850) (cl:go pc-5850))
     pc-5845
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5846)
     pc-5846
       (cl:when flag (cl:setf pc 5855) (cl:go pc-5855))
     pc-5847
       (cl:setf continue (cl:cons '|compilation-unit| 5858))
       (cl:setf pc 5848)
     pc-5848
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5849)
     pc-5849
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5850
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5851)
     pc-5851
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5852)
     pc-5852
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5853)
     pc-5853
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5854)
     pc-5854
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5855
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5856)
     pc-5856
       (cl:setf pc 5858) (cl:go pc-5858)
     pc-5857
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5858)
     pc-5858
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5859)
     pc-5859
       (cl:funcall (get-operation '|define-variable!|) '|*source-maps*| val env)
       (cl:setf pc 5860)
     pc-5860
       (cl:setf val val)
       (cl:setf pc 5861)
     pc-5861
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 5862)
     pc-5862
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 5864 env))
       (cl:setf pc 5863)
     pc-5863
       (cl:setf pc 6358) (cl:go pc-6358)
     pc-5864
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5865)
     pc-5865
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|space-name| |source-map-field|) argl env 0))
       (cl:setf pc 5866)
     pc-5866
       (cl:setf val "Register source-map entries from an ecec-header source-map field.
SPACE-NAME is a symbol, SOURCE-MAP-FIELD is (filename (pc line col) ...).")
       (cl:setf pc 5867)
     pc-5867
       (cl:push continue stack)
       (cl:setf pc 5868)
     pc-5868
       (cl:push env stack)
       (cl:setf pc 5869)
     pc-5869
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 5870)
     pc-5870
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 5871)
     pc-5871
       (cl:when flag (cl:setf pc 5914) (cl:go pc-5914))
     pc-5872
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 5873)
     pc-5873
       (cl:push proc stack)
       (cl:setf pc 5874)
     pc-5874
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 5875)
     pc-5875
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 5876)
     pc-5876
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5877)
     pc-5877
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5878)
     pc-5878
       (cl:when flag (cl:setf pc 5893) (cl:go pc-5893))
     pc-5879
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5880)
     pc-5880
       (cl:when flag (cl:setf pc 5886) (cl:go pc-5886))
     pc-5881
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5882)
     pc-5882
       (cl:when flag (cl:setf pc 5891) (cl:go pc-5891))
     pc-5883
       (cl:setf continue (cl:cons '|compilation-unit| 5894))
       (cl:setf pc 5884)
     pc-5884
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5885)
     pc-5885
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5886
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5887)
     pc-5887
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5888)
     pc-5888
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5889)
     pc-5889
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5890)
     pc-5890
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5891
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5892)
     pc-5892
       (cl:setf pc 5894) (cl:go pc-5894)
     pc-5893
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5894)
     pc-5894
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5895)
     pc-5895
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 5896)
     pc-5896
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5897)
     pc-5897
       (cl:when flag (cl:setf pc 5912) (cl:go pc-5912))
     pc-5898
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5899)
     pc-5899
       (cl:when flag (cl:setf pc 5905) (cl:go pc-5905))
     pc-5900
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5901)
     pc-5901
       (cl:when flag (cl:setf pc 5910) (cl:go pc-5910))
     pc-5902
       (cl:setf continue (cl:cons '|compilation-unit| 5915))
       (cl:setf pc 5903)
     pc-5903
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5904)
     pc-5904
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5905
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5906)
     pc-5906
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5907)
     pc-5907
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5908)
     pc-5908
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5909)
     pc-5909
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5910
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5911)
     pc-5911
       (cl:setf pc 5915) (cl:go pc-5915)
     pc-5912
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5913)
     pc-5913
       (cl:setf pc 5915) (cl:go pc-5915)
     pc-5914
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 5915)
     pc-5915
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5916)
     pc-5916
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5917)
     pc-5917
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 5918)
     pc-5918
       (cl:when flag (cl:setf pc 6356) (cl:go pc-6356))
     pc-5919
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 5921 env))
       (cl:setf pc 5920)
     pc-5920
       (cl:setf pc 6290) (cl:go pc-6290)
     pc-5921
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5922)
     pc-5922
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|filename| |ht|) argl env 0))
       (cl:setf pc 5923)
     pc-5923
       (cl:push continue stack)
       (cl:setf pc 5924)
     pc-5924
       (cl:push env stack)
       (cl:setf pc 5925)
     pc-5925
       (cl:push env stack)
       (cl:setf pc 5926)
     pc-5926
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 5928 env))
       (cl:setf pc 5927)
     pc-5927
       (cl:setf pc 6202) (cl:go pc-6202)
     pc-5928
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5929)
     pc-5929
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|loop|) argl env 0))
       (cl:setf pc 5930)
     pc-5930
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 5932 env))
       (cl:setf pc 5931)
     pc-5931
       (cl:setf pc 5939) (cl:go pc-5939)
     pc-5932
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5933)
     pc-5933
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|g184|) argl env 0))
       (cl:setf pc 5934)
     pc-5934
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5935)
     pc-5935
       (cl:funcall (get-operation '|lexical-set!|) 1 0 val env)
       (cl:setf pc 5936)
     pc-5936
       (cl:setf val val)
       (cl:setf pc 5937)
     pc-5937
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 5938)
     pc-5938
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5939
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 5941 env))
       (cl:setf pc 5940)
     pc-5940
       (cl:setf pc 6184) (cl:go pc-6184)
     pc-5941
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5942)
     pc-5942
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|entries|) argl env 0))
       (cl:setf pc 5943)
     pc-5943
       (cl:push continue stack)
       (cl:setf pc 5944)
     pc-5944
       (cl:push env stack)
       (cl:setf pc 5945)
     pc-5945
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|pair?| env))
       (cl:setf pc 5946)
     pc-5946
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5947)
     pc-5947
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5948)
     pc-5948
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5949)
     pc-5949
       (cl:when flag (cl:setf pc 5964) (cl:go pc-5964))
     pc-5950
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5951)
     pc-5951
       (cl:when flag (cl:setf pc 5957) (cl:go pc-5957))
     pc-5952
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5953)
     pc-5953
       (cl:when flag (cl:setf pc 5962) (cl:go pc-5962))
     pc-5954
       (cl:setf continue (cl:cons '|compilation-unit| 5965))
       (cl:setf pc 5955)
     pc-5955
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5956)
     pc-5956
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5957
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5958)
     pc-5958
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5959)
     pc-5959
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5960)
     pc-5960
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5961)
     pc-5961
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5962
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 5963)
     pc-5963
       (cl:setf pc 5965) (cl:go pc-5965)
     pc-5964
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 5965)
     pc-5965
       (cl:setf env (cl:pop stack))
       (cl:setf pc 5966)
     pc-5966
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 5967)
     pc-5967
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 5968)
     pc-5968
       (cl:when flag (cl:setf pc 6182) (cl:go pc-6182))
     pc-5969
       (cl:push continue stack)
       (cl:setf pc 5970)
     pc-5970
       (cl:push env stack)
       (cl:setf pc 5971)
     pc-5971
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 5973 env))
       (cl:setf pc 5972)
     pc-5972
       (cl:setf pc 6097) (cl:go pc-6097)
     pc-5973
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 5974)
     pc-5974
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|entry|) argl env 0))
       (cl:setf pc 5975)
     pc-5975
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|hash-set!| env))
       (cl:setf pc 5976)
     pc-5976
       (cl:push continue stack)
       (cl:setf pc 5977)
     pc-5977
       (cl:push proc stack)
       (cl:setf pc 5978)
     pc-5978
       (cl:push env stack)
       (cl:setf pc 5979)
     pc-5979
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 5980)
     pc-5980
       (cl:push proc stack)
       (cl:setf pc 5981)
     pc-5981
       (cl:push env stack)
       (cl:setf pc 5982)
     pc-5982
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|caddr| env))
       (cl:setf pc 5983)
     pc-5983
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 5984)
     pc-5984
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 5985)
     pc-5985
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 5986)
     pc-5986
       (cl:when flag (cl:setf pc 6001) (cl:go pc-6001))
     pc-5987
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 5988)
     pc-5988
       (cl:when flag (cl:setf pc 5994) (cl:go pc-5994))
     pc-5989
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 5990)
     pc-5990
       (cl:when flag (cl:setf pc 5999) (cl:go pc-5999))
     pc-5991
       (cl:setf continue (cl:cons '|compilation-unit| 6002))
       (cl:setf pc 5992)
     pc-5992
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 5993)
     pc-5993
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5994
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 5995)
     pc-5995
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 5996)
     pc-5996
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 5997)
     pc-5997
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 5998)
     pc-5998
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-5999
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6000)
     pc-6000
       (cl:setf pc 6002) (cl:go pc-6002)
     pc-6001
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6002)
     pc-6002
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6003)
     pc-6003
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6004)
     pc-6004
       (cl:push env stack)
       (cl:setf pc 6005)
     pc-6005
       (cl:push argl stack)
       (cl:setf pc 6006)
     pc-6006
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 6007)
     pc-6007
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6008)
     pc-6008
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6009)
     pc-6009
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6010)
     pc-6010
       (cl:when flag (cl:setf pc 6025) (cl:go pc-6025))
     pc-6011
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6012)
     pc-6012
       (cl:when flag (cl:setf pc 6018) (cl:go pc-6018))
     pc-6013
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6014)
     pc-6014
       (cl:when flag (cl:setf pc 6023) (cl:go pc-6023))
     pc-6015
       (cl:setf continue (cl:cons '|compilation-unit| 6026))
       (cl:setf pc 6016)
     pc-6016
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6017)
     pc-6017
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6018
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6019)
     pc-6019
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6020)
     pc-6020
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6021)
     pc-6021
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6022)
     pc-6022
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6023
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6024)
     pc-6024
       (cl:setf pc 6026) (cl:go pc-6026)
     pc-6025
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6026)
     pc-6026
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 6027)
     pc-6027
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6028)
     pc-6028
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6029)
     pc-6029
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 3 0 env))
       (cl:setf pc 6030)
     pc-6030
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6031)
     pc-6031
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6032)
     pc-6032
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6033)
     pc-6033
       (cl:when flag (cl:setf pc 6048) (cl:go pc-6048))
     pc-6034
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6035)
     pc-6035
       (cl:when flag (cl:setf pc 6041) (cl:go pc-6041))
     pc-6036
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6037)
     pc-6037
       (cl:when flag (cl:setf pc 6046) (cl:go pc-6046))
     pc-6038
       (cl:setf continue (cl:cons '|compilation-unit| 6049))
       (cl:setf pc 6039)
     pc-6039
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6040)
     pc-6040
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6041
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6042)
     pc-6042
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6043)
     pc-6043
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6044)
     pc-6044
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6045)
     pc-6045
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6046
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6047)
     pc-6047
       (cl:setf pc 6049) (cl:go pc-6049)
     pc-6048
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6049)
     pc-6049
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6050)
     pc-6050
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6051)
     pc-6051
       (cl:push env stack)
       (cl:setf pc 6052)
     pc-6052
       (cl:push argl stack)
       (cl:setf pc 6053)
     pc-6053
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 6054)
     pc-6054
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6055)
     pc-6055
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6056)
     pc-6056
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6057)
     pc-6057
       (cl:when flag (cl:setf pc 6072) (cl:go pc-6072))
     pc-6058
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6059)
     pc-6059
       (cl:when flag (cl:setf pc 6065) (cl:go pc-6065))
     pc-6060
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6061)
     pc-6061
       (cl:when flag (cl:setf pc 6070) (cl:go pc-6070))
     pc-6062
       (cl:setf continue (cl:cons '|compilation-unit| 6073))
       (cl:setf pc 6063)
     pc-6063
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6064)
     pc-6064
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6065
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6066)
     pc-6066
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6067)
     pc-6067
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6068)
     pc-6068
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6069)
     pc-6069
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6070
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6071)
     pc-6071
       (cl:setf pc 6073) (cl:go pc-6073)
     pc-6072
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6073)
     pc-6073
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 6074)
     pc-6074
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6075)
     pc-6075
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6076)
     pc-6076
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 3 1 env))
       (cl:setf pc 6077)
     pc-6077
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6078)
     pc-6078
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6079)
     pc-6079
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6080)
     pc-6080
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6081)
     pc-6081
       (cl:when flag (cl:setf pc 6095) (cl:go pc-6095))
     pc-6082
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6083)
     pc-6083
       (cl:when flag (cl:setf pc 6088) (cl:go pc-6088))
     pc-6084
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6085)
     pc-6085
       (cl:when flag (cl:setf pc 6093) (cl:go pc-6093))
     pc-6086
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6087)
     pc-6087
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6088
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6089)
     pc-6089
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6090)
     pc-6090
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6091)
     pc-6091
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6092)
     pc-6092
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6093
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6094)
     pc-6094
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6095
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6096)
     pc-6096
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6097
       (cl:push proc stack)
       (cl:setf pc 6098)
     pc-6098
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 6099)
     pc-6099
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6100)
     pc-6100
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6101)
     pc-6101
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6102)
     pc-6102
       (cl:when flag (cl:setf pc 6117) (cl:go pc-6117))
     pc-6103
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6104)
     pc-6104
       (cl:when flag (cl:setf pc 6110) (cl:go pc-6110))
     pc-6105
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6106)
     pc-6106
       (cl:when flag (cl:setf pc 6115) (cl:go pc-6115))
     pc-6107
       (cl:setf continue (cl:cons '|compilation-unit| 6118))
       (cl:setf pc 6108)
     pc-6108
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6109)
     pc-6109
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6110
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6111)
     pc-6111
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6112)
     pc-6112
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6113)
     pc-6113
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6114)
     pc-6114
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6115
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6116)
     pc-6116
       (cl:setf pc 6118) (cl:go pc-6118)
     pc-6117
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6118)
     pc-6118
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6119)
     pc-6119
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6120)
     pc-6120
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6121)
     pc-6121
       (cl:when flag (cl:setf pc 6136) (cl:go pc-6136))
     pc-6122
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6123)
     pc-6123
       (cl:when flag (cl:setf pc 6129) (cl:go pc-6129))
     pc-6124
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6125)
     pc-6125
       (cl:when flag (cl:setf pc 6134) (cl:go pc-6134))
     pc-6126
       (cl:setf continue (cl:cons '|compilation-unit| 6137))
       (cl:setf pc 6127)
     pc-6127
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6128)
     pc-6128
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6129
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6130)
     pc-6130
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6131)
     pc-6131
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6132)
     pc-6132
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6133)
     pc-6133
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6134
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6135)
     pc-6135
       (cl:setf pc 6137) (cl:go pc-6137)
     pc-6136
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6137)
     pc-6137
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6138)
     pc-6138
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6139)
     pc-6139
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 6140)
     pc-6140
       (cl:push continue stack)
       (cl:setf pc 6141)
     pc-6141
       (cl:push proc stack)
       (cl:setf pc 6142)
     pc-6142
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 6143)
     pc-6143
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6144)
     pc-6144
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6145)
     pc-6145
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6146)
     pc-6146
       (cl:when flag (cl:setf pc 6161) (cl:go pc-6161))
     pc-6147
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6148)
     pc-6148
       (cl:when flag (cl:setf pc 6154) (cl:go pc-6154))
     pc-6149
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6150)
     pc-6150
       (cl:when flag (cl:setf pc 6159) (cl:go pc-6159))
     pc-6151
       (cl:setf continue (cl:cons '|compilation-unit| 6162))
       (cl:setf pc 6152)
     pc-6152
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6153)
     pc-6153
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6154
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6155)
     pc-6155
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6156)
     pc-6156
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6157)
     pc-6157
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6158)
     pc-6158
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6159
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6160)
     pc-6160
       (cl:setf pc 6162) (cl:go pc-6162)
     pc-6161
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6162)
     pc-6162
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6163)
     pc-6163
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6164)
     pc-6164
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6165)
     pc-6165
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6166)
     pc-6166
       (cl:when flag (cl:setf pc 6180) (cl:go pc-6180))
     pc-6167
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6168)
     pc-6168
       (cl:when flag (cl:setf pc 6173) (cl:go pc-6173))
     pc-6169
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6170)
     pc-6170
       (cl:when flag (cl:setf pc 6178) (cl:go pc-6178))
     pc-6171
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6172)
     pc-6172
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6173
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6174)
     pc-6174
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6175)
     pc-6175
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6176)
     pc-6176
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6177)
     pc-6177
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6178
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6179)
     pc-6179
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6180
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6181)
     pc-6181
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6182
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 6183)
     pc-6183
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6184
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6185)
     pc-6185
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6186)
     pc-6186
       (cl:when flag (cl:setf pc 6200) (cl:go pc-6200))
     pc-6187
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6188)
     pc-6188
       (cl:when flag (cl:setf pc 6193) (cl:go pc-6193))
     pc-6189
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6190)
     pc-6190
       (cl:when flag (cl:setf pc 6198) (cl:go pc-6198))
     pc-6191
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6192)
     pc-6192
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6193
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6194)
     pc-6194
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6195)
     pc-6195
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6196)
     pc-6196
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6197)
     pc-6197
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6198
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6199)
     pc-6199
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6200
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6201)
     pc-6201
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6202
       (cl:setf val cl:nil)
       (cl:setf pc 6203)
     pc-6203
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6204)
     pc-6204
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6205)
     pc-6205
       (cl:when flag (cl:setf pc 6222) (cl:go pc-6222))
     pc-6206
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6207)
     pc-6207
       (cl:when flag (cl:setf pc 6215) (cl:go pc-6215))
     pc-6208
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6209)
     pc-6209
       (cl:when flag (cl:setf pc 6220) (cl:go pc-6220))
     pc-6210
       (cl:setf continue (cl:cons '|compilation-unit| 6213))
       (cl:setf pc 6211)
     pc-6211
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6212)
     pc-6212
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6213
       (cl:setf proc val)
       (cl:setf pc 6214)
     pc-6214
       (cl:setf pc 6223) (cl:go pc-6223)
     pc-6215
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6216)
     pc-6216
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6217)
     pc-6217
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6218)
     pc-6218
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6219)
     pc-6219
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6220
       (cl:setf proc (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6221)
     pc-6221
       (cl:setf pc 6223) (cl:go pc-6223)
     pc-6222
       (cl:setf proc (cl:funcall (get-operation '|apply-primitive-procedure|) proc argl))
       (cl:setf pc 6223)
     pc-6223
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6224)
     pc-6224
       (cl:push proc stack)
       (cl:setf pc 6225)
     pc-6225
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 6226)
     pc-6226
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 6227)
     pc-6227
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6228)
     pc-6228
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6229)
     pc-6229
       (cl:when flag (cl:setf pc 6244) (cl:go pc-6244))
     pc-6230
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6231)
     pc-6231
       (cl:when flag (cl:setf pc 6237) (cl:go pc-6237))
     pc-6232
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6233)
     pc-6233
       (cl:when flag (cl:setf pc 6242) (cl:go pc-6242))
     pc-6234
       (cl:setf continue (cl:cons '|compilation-unit| 6245))
       (cl:setf pc 6235)
     pc-6235
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6236)
     pc-6236
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6237
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6238)
     pc-6238
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6239)
     pc-6239
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6240)
     pc-6240
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6241)
     pc-6241
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6242
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6243)
     pc-6243
       (cl:setf pc 6245) (cl:go pc-6245)
     pc-6244
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6245)
     pc-6245
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6246)
     pc-6246
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6247)
     pc-6247
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6248)
     pc-6248
       (cl:when flag (cl:setf pc 6263) (cl:go pc-6263))
     pc-6249
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6250)
     pc-6250
       (cl:when flag (cl:setf pc 6256) (cl:go pc-6256))
     pc-6251
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6252)
     pc-6252
       (cl:when flag (cl:setf pc 6261) (cl:go pc-6261))
     pc-6253
       (cl:setf continue (cl:cons '|compilation-unit| 6264))
       (cl:setf pc 6254)
     pc-6254
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6255)
     pc-6255
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6256
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6257)
     pc-6257
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6258)
     pc-6258
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6259)
     pc-6259
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6260)
     pc-6260
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6261
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6262)
     pc-6262
       (cl:setf pc 6264) (cl:go pc-6264)
     pc-6263
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6264)
     pc-6264
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6265)
     pc-6265
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6266)
     pc-6266
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|hash-set!| env))
       (cl:setf pc 6267)
     pc-6267
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 6268)
     pc-6268
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6269)
     pc-6269
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 6270)
     pc-6270
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6271)
     pc-6271
       (cl:setf val (cl:funcall (get-operation '|lookup-variable-value|) '|*source-maps*| env))
       (cl:setf pc 6272)
     pc-6272
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6273)
     pc-6273
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6274)
     pc-6274
       (cl:when flag (cl:setf pc 6288) (cl:go pc-6288))
     pc-6275
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6276)
     pc-6276
       (cl:when flag (cl:setf pc 6281) (cl:go pc-6281))
     pc-6277
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6278)
     pc-6278
       (cl:when flag (cl:setf pc 6286) (cl:go pc-6286))
     pc-6279
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6280)
     pc-6280
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6281
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6282)
     pc-6282
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6283)
     pc-6283
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6284)
     pc-6284
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6285)
     pc-6285
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6286
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6287)
     pc-6287
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6288
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6289)
     pc-6289
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6290
       (cl:push continue stack)
       (cl:setf pc 6291)
     pc-6291
       (cl:push proc stack)
       (cl:setf pc 6292)
     pc-6292
       (cl:push env stack)
       (cl:setf pc 6293)
     pc-6293
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%make-hash-table| env))
       (cl:setf pc 6294)
     pc-6294
       (cl:setf argl cl:nil)
       (cl:setf pc 6295)
     pc-6295
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6296)
     pc-6296
       (cl:when flag (cl:setf pc 6311) (cl:go pc-6311))
     pc-6297
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6298)
     pc-6298
       (cl:when flag (cl:setf pc 6304) (cl:go pc-6304))
     pc-6299
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6300)
     pc-6300
       (cl:when flag (cl:setf pc 6309) (cl:go pc-6309))
     pc-6301
       (cl:setf continue (cl:cons '|compilation-unit| 6312))
       (cl:setf pc 6302)
     pc-6302
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6303)
     pc-6303
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6304
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6305)
     pc-6305
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6306)
     pc-6306
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6307)
     pc-6307
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6308)
     pc-6308
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6309
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6310)
     pc-6310
       (cl:setf pc 6312) (cl:go pc-6312)
     pc-6311
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6312)
     pc-6312
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6313)
     pc-6313
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6314)
     pc-6314
       (cl:push argl stack)
       (cl:setf pc 6315)
     pc-6315
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|car| env))
       (cl:setf pc 6316)
     pc-6316
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 1 env))
       (cl:setf pc 6317)
     pc-6317
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6318)
     pc-6318
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6319)
     pc-6319
       (cl:when flag (cl:setf pc 6334) (cl:go pc-6334))
     pc-6320
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6321)
     pc-6321
       (cl:when flag (cl:setf pc 6327) (cl:go pc-6327))
     pc-6322
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6323)
     pc-6323
       (cl:when flag (cl:setf pc 6332) (cl:go pc-6332))
     pc-6324
       (cl:setf continue (cl:cons '|compilation-unit| 6335))
       (cl:setf pc 6325)
     pc-6325
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6326)
     pc-6326
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6327
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6328)
     pc-6328
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6329)
     pc-6329
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6330)
     pc-6330
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6331)
     pc-6331
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6332
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6333)
     pc-6333
       (cl:setf pc 6335) (cl:go pc-6335)
     pc-6334
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6335)
     pc-6335
       (cl:setf argl (cl:pop stack))
       (cl:setf pc 6336)
     pc-6336
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6337)
     pc-6337
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6338)
     pc-6338
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6339)
     pc-6339
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6340)
     pc-6340
       (cl:when flag (cl:setf pc 6354) (cl:go pc-6354))
     pc-6341
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6342)
     pc-6342
       (cl:when flag (cl:setf pc 6347) (cl:go pc-6347))
     pc-6343
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6344)
     pc-6344
       (cl:when flag (cl:setf pc 6352) (cl:go pc-6352))
     pc-6345
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6346)
     pc-6346
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6347
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6348)
     pc-6348
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6349)
     pc-6349
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6350)
     pc-6350
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6351)
     pc-6351
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6352
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6353)
     pc-6353
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6354
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6355)
     pc-6355
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6356
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 6357)
     pc-6357
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6358
       (cl:funcall (get-operation '|define-variable!|) '|register-source-map!| val env)
       (cl:setf pc 6359)
     pc-6359
       (cl:setf val val)
       (cl:setf pc 6360)
     pc-6360
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 6361)
     pc-6361
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 6363 env))
       (cl:setf pc 6362)
     pc-6362
       (cl:setf pc 6445) (cl:go pc-6445)
     pc-6363
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6364)
     pc-6364
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|space-name| |pc|) argl env 0))
       (cl:setf pc 6365)
     pc-6365
       (cl:setf val "Look up PC in source-map for SPACE-NAME. Returns (file line col) or #f.")
       (cl:setf pc 6366)
     pc-6366
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 6368 env))
       (cl:setf pc 6367)
     pc-6367
       (cl:setf pc 6399) (cl:go pc-6399)
     pc-6368
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6369)
     pc-6369
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|space-map|) argl env 0))
       (cl:setf pc 6370)
     pc-6370
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6371)
     pc-6371
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 6372)
     pc-6372
       (cl:when flag (cl:setf pc 6397) (cl:go pc-6397))
     pc-6373
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|hash-ref| env))
       (cl:setf pc 6374)
     pc-6374
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 6375)
     pc-6375
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6376)
     pc-6376
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 1 env))
       (cl:setf pc 6377)
     pc-6377
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6378)
     pc-6378
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6379)
     pc-6379
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6380)
     pc-6380
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6381)
     pc-6381
       (cl:when flag (cl:setf pc 6395) (cl:go pc-6395))
     pc-6382
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6383)
     pc-6383
       (cl:when flag (cl:setf pc 6388) (cl:go pc-6388))
     pc-6384
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6385)
     pc-6385
       (cl:when flag (cl:setf pc 6393) (cl:go pc-6393))
     pc-6386
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6387)
     pc-6387
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6388
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6389)
     pc-6389
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6390)
     pc-6390
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6391)
     pc-6391
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6392)
     pc-6392
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6393
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6394)
     pc-6394
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6395
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6396)
     pc-6396
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6397
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 6398)
     pc-6398
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6399
       (cl:push continue stack)
       (cl:setf pc 6400)
     pc-6400
       (cl:push proc stack)
       (cl:setf pc 6401)
     pc-6401
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|hash-ref| env))
       (cl:setf pc 6402)
     pc-6402
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 6403)
     pc-6403
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6404)
     pc-6404
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6405)
     pc-6405
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6406)
     pc-6406
       (cl:setf val (cl:funcall (get-operation '|lookup-variable-value|) '|*source-maps*| env))
       (cl:setf pc 6407)
     pc-6407
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6408)
     pc-6408
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6409)
     pc-6409
       (cl:when flag (cl:setf pc 6424) (cl:go pc-6424))
     pc-6410
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6411)
     pc-6411
       (cl:when flag (cl:setf pc 6417) (cl:go pc-6417))
     pc-6412
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6413)
     pc-6413
       (cl:when flag (cl:setf pc 6422) (cl:go pc-6422))
     pc-6414
       (cl:setf continue (cl:cons '|compilation-unit| 6425))
       (cl:setf pc 6415)
     pc-6415
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6416)
     pc-6416
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6417
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6418)
     pc-6418
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6419)
     pc-6419
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6420)
     pc-6420
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6421)
     pc-6421
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6422
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6423)
     pc-6423
       (cl:setf pc 6425) (cl:go pc-6425)
     pc-6424
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6425)
     pc-6425
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6426)
     pc-6426
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6427)
     pc-6427
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6428)
     pc-6428
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6429)
     pc-6429
       (cl:when flag (cl:setf pc 6443) (cl:go pc-6443))
     pc-6430
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6431)
     pc-6431
       (cl:when flag (cl:setf pc 6436) (cl:go pc-6436))
     pc-6432
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6433)
     pc-6433
       (cl:when flag (cl:setf pc 6441) (cl:go pc-6441))
     pc-6434
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6435)
     pc-6435
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6436
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6437)
     pc-6437
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6438)
     pc-6438
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6439)
     pc-6439
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6440)
     pc-6440
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6441
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6442)
     pc-6442
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6443
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6444)
     pc-6444
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6445
       (cl:funcall (get-operation '|define-variable!|) '|resolve-source-location| val env)
       (cl:setf pc 6446)
     pc-6446
       (cl:setf val val)
       (cl:setf pc 6447)
     pc-6447
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 6448)
     pc-6448
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 6450 env))
       (cl:setf pc 6449)
     pc-6449
       (cl:setf pc 7043) (cl:go pc-7043)
     pc-6450
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6451)
     pc-6451
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|port|) argl env 0))
       (cl:setf pc 6452)
     pc-6452
       (cl:setf val "Load one ecec section (header + instructions) from PORT.
Creates a named space, registers source-map if present, and executes.
Returns the result of executing the section, or eof if no more sections.")
       (cl:setf pc 6453)
     pc-6453
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 6455 env))
       (cl:setf pc 6454)
     pc-6454
       (cl:setf pc 7001) (cl:go pc-7001)
     pc-6455
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6456)
     pc-6456
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|header|) argl env 0))
       (cl:setf pc 6457)
     pc-6457
       (cl:push continue stack)
       (cl:setf pc 6458)
     pc-6458
       (cl:push env stack)
       (cl:setf pc 6459)
     pc-6459
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eof?| env))
       (cl:setf pc 6460)
     pc-6460
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6461)
     pc-6461
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6462)
     pc-6462
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6463)
     pc-6463
       (cl:when flag (cl:setf pc 6478) (cl:go pc-6478))
     pc-6464
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6465)
     pc-6465
       (cl:when flag (cl:setf pc 6471) (cl:go pc-6471))
     pc-6466
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6467)
     pc-6467
       (cl:when flag (cl:setf pc 6476) (cl:go pc-6476))
     pc-6468
       (cl:setf continue (cl:cons '|compilation-unit| 6479))
       (cl:setf pc 6469)
     pc-6469
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6470)
     pc-6470
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6471
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6472)
     pc-6472
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6473)
     pc-6473
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6474)
     pc-6474
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6475)
     pc-6475
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6476
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6477)
     pc-6477
       (cl:setf pc 6479) (cl:go pc-6479)
     pc-6478
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6479)
     pc-6479
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6480)
     pc-6480
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6481)
     pc-6481
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 6482)
     pc-6482
       (cl:when flag (cl:setf pc 6485) (cl:go pc-6485))
     pc-6483
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6484)
     pc-6484
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6485
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 6487 env))
       (cl:setf pc 6486)
     pc-6486
       (cl:setf pc 6915) (cl:go pc-6915)
     pc-6487
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6488)
     pc-6488
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|space-sym|) argl env 0))
       (cl:setf pc 6489)
     pc-6489
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 6491 env))
       (cl:setf pc 6490)
     pc-6490
       (cl:setf pc 6801) (cl:go pc-6801)
     pc-6491
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6492)
     pc-6492
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|source-map-field|) argl env 0))
       (cl:setf pc 6493)
     pc-6493
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 6495 env))
       (cl:setf pc 6494)
     pc-6494
       (cl:setf pc 6760) (cl:go pc-6760)
     pc-6495
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6496)
     pc-6496
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|prev-space|) argl env 0))
       (cl:setf pc 6497)
     pc-6497
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 6499 env))
       (cl:setf pc 6498)
     pc-6498
       (cl:setf pc 6697) (cl:go pc-6697)
     pc-6499
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6500)
     pc-6500
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|new-space|) argl env 0))
       (cl:setf pc 6501)
     pc-6501
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 6503 env))
       (cl:setf pc 6502)
     pc-6502
       (cl:setf pc 6655) (cl:go pc-6655)
     pc-6503
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6504)
     pc-6504
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|instrs|) argl env 0))
       (cl:setf pc 6505)
     pc-6505
       (cl:push continue stack)
       (cl:setf pc 6506)
     pc-6506
       (cl:push env stack)
       (cl:setf pc 6507)
     pc-6507
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 3 0 env))
       (cl:setf pc 6508)
     pc-6508
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 6509)
     pc-6509
       (cl:when flag (cl:setf pc 6533) (cl:go pc-6533))
     pc-6510
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|register-source-map!| env))
       (cl:setf pc 6511)
     pc-6511
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 3 0 env))
       (cl:setf pc 6512)
     pc-6512
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6513)
     pc-6513
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 4 0 env))
       (cl:setf pc 6514)
     pc-6514
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6515)
     pc-6515
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6516)
     pc-6516
       (cl:when flag (cl:setf pc 6531) (cl:go pc-6531))
     pc-6517
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6518)
     pc-6518
       (cl:when flag (cl:setf pc 6524) (cl:go pc-6524))
     pc-6519
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6520)
     pc-6520
       (cl:when flag (cl:setf pc 6529) (cl:go pc-6529))
     pc-6521
       (cl:setf continue (cl:cons '|compilation-unit| 6534))
       (cl:setf pc 6522)
     pc-6522
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6523)
     pc-6523
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6524
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6525)
     pc-6525
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6526)
     pc-6526
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6527)
     pc-6527
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6528)
     pc-6528
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6529
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6530)
     pc-6530
       (cl:setf pc 6534) (cl:go pc-6534)
     pc-6531
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6532)
     pc-6532
       (cl:setf pc 6534) (cl:go pc-6534)
     pc-6533
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 6534)
     pc-6534
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6535)
     pc-6535
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6536)
     pc-6536
       (cl:push continue stack)
       (cl:setf pc 6537)
     pc-6537
       (cl:push env stack)
       (cl:setf pc 6538)
     pc-6538
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%set-current-space-id!| env))
       (cl:setf pc 6539)
     pc-6539
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 6540)
     pc-6540
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6541)
     pc-6541
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6542)
     pc-6542
       (cl:when flag (cl:setf pc 6557) (cl:go pc-6557))
     pc-6543
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6544)
     pc-6544
       (cl:when flag (cl:setf pc 6550) (cl:go pc-6550))
     pc-6545
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6546)
     pc-6546
       (cl:when flag (cl:setf pc 6555) (cl:go pc-6555))
     pc-6547
       (cl:setf continue (cl:cons '|compilation-unit| 6558))
       (cl:setf pc 6548)
     pc-6548
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6549)
     pc-6549
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6550
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6551)
     pc-6551
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6552)
     pc-6552
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6553)
     pc-6553
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6554)
     pc-6554
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6555
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6556)
     pc-6556
       (cl:setf pc 6558) (cl:go pc-6558)
     pc-6557
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6558)
     pc-6558
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6559)
     pc-6559
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6560)
     pc-6560
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 6562 env))
       (cl:setf pc 6561)
     pc-6561
       (cl:setf pc 6590) (cl:go pc-6590)
     pc-6562
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6563)
     pc-6563
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|result|) argl env 0))
       (cl:setf pc 6564)
     pc-6564
       (cl:push continue stack)
       (cl:setf pc 6565)
     pc-6565
       (cl:push env stack)
       (cl:setf pc 6566)
     pc-6566
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%set-current-space-id!| env))
       (cl:setf pc 6567)
     pc-6567
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 3 0 env))
       (cl:setf pc 6568)
     pc-6568
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6569)
     pc-6569
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6570)
     pc-6570
       (cl:when flag (cl:setf pc 6585) (cl:go pc-6585))
     pc-6571
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6572)
     pc-6572
       (cl:when flag (cl:setf pc 6578) (cl:go pc-6578))
     pc-6573
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6574)
     pc-6574
       (cl:when flag (cl:setf pc 6583) (cl:go pc-6583))
     pc-6575
       (cl:setf continue (cl:cons '|compilation-unit| 6586))
       (cl:setf pc 6576)
     pc-6576
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6577)
     pc-6577
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6578
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6579)
     pc-6579
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6580)
     pc-6580
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6581)
     pc-6581
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6582)
     pc-6582
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6583
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6584)
     pc-6584
       (cl:setf pc 6586) (cl:go pc-6586)
     pc-6585
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6586)
     pc-6586
       (cl:setf env (cl:pop stack))
       (cl:setf pc 6587)
     pc-6587
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6588)
     pc-6588
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6589)
     pc-6589
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6590
       (cl:push continue stack)
       (cl:setf pc 6591)
     pc-6591
       (cl:push proc stack)
       (cl:setf pc 6592)
     pc-6592
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|execute| env))
       (cl:setf pc 6593)
     pc-6593
       (cl:push proc stack)
       (cl:setf pc 6594)
     pc-6594
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|list| env))
       (cl:setf pc 6595)
     pc-6595
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6596)
     pc-6596
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6597)
     pc-6597
       (cl:setf val '|compiled-unit|)
       (cl:setf pc 6598)
     pc-6598
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6599)
     pc-6599
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6600)
     pc-6600
       (cl:when flag (cl:setf pc 6615) (cl:go pc-6615))
     pc-6601
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6602)
     pc-6602
       (cl:when flag (cl:setf pc 6608) (cl:go pc-6608))
     pc-6603
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6604)
     pc-6604
       (cl:when flag (cl:setf pc 6613) (cl:go pc-6613))
     pc-6605
       (cl:setf continue (cl:cons '|compilation-unit| 6616))
       (cl:setf pc 6606)
     pc-6606
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6607)
     pc-6607
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6608
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6609)
     pc-6609
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6610)
     pc-6610
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6611)
     pc-6611
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6612)
     pc-6612
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6613
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6614)
     pc-6614
       (cl:setf pc 6616) (cl:go pc-6616)
     pc-6615
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6616)
     pc-6616
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6617)
     pc-6617
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6618)
     pc-6618
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6619)
     pc-6619
       (cl:when flag (cl:setf pc 6634) (cl:go pc-6634))
     pc-6620
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6621)
     pc-6621
       (cl:when flag (cl:setf pc 6627) (cl:go pc-6627))
     pc-6622
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6623)
     pc-6623
       (cl:when flag (cl:setf pc 6632) (cl:go pc-6632))
     pc-6624
       (cl:setf continue (cl:cons '|compilation-unit| 6635))
       (cl:setf pc 6625)
     pc-6625
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6626)
     pc-6626
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6627
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6628)
     pc-6628
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6629)
     pc-6629
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6630)
     pc-6630
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6631)
     pc-6631
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6632
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6633)
     pc-6633
       (cl:setf pc 6635) (cl:go pc-6635)
     pc-6634
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6635)
     pc-6635
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6636)
     pc-6636
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6637)
     pc-6637
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6638)
     pc-6638
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6639)
     pc-6639
       (cl:when flag (cl:setf pc 6653) (cl:go pc-6653))
     pc-6640
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6641)
     pc-6641
       (cl:when flag (cl:setf pc 6646) (cl:go pc-6646))
     pc-6642
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6643)
     pc-6643
       (cl:when flag (cl:setf pc 6651) (cl:go pc-6651))
     pc-6644
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6645)
     pc-6645
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6646
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6647)
     pc-6647
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6648)
     pc-6648
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6649)
     pc-6649
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6650)
     pc-6650
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6651
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6652)
     pc-6652
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6653
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6654)
     pc-6654
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6655
       (cl:push continue stack)
       (cl:setf pc 6656)
     pc-6656
       (cl:push proc stack)
       (cl:setf pc 6657)
     pc-6657
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|ece-scheme-read| env))
       (cl:setf pc 6658)
     pc-6658
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 5 0 env))
       (cl:setf pc 6659)
     pc-6659
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6660)
     pc-6660
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6661)
     pc-6661
       (cl:when flag (cl:setf pc 6676) (cl:go pc-6676))
     pc-6662
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6663)
     pc-6663
       (cl:when flag (cl:setf pc 6669) (cl:go pc-6669))
     pc-6664
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6665)
     pc-6665
       (cl:when flag (cl:setf pc 6674) (cl:go pc-6674))
     pc-6666
       (cl:setf continue (cl:cons '|compilation-unit| 6677))
       (cl:setf pc 6667)
     pc-6667
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6668)
     pc-6668
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6669
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6670)
     pc-6670
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6671)
     pc-6671
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6672)
     pc-6672
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6673)
     pc-6673
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6674
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6675)
     pc-6675
       (cl:setf pc 6677) (cl:go pc-6677)
     pc-6676
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6677)
     pc-6677
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6678)
     pc-6678
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6679)
     pc-6679
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6680)
     pc-6680
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6681)
     pc-6681
       (cl:when flag (cl:setf pc 6695) (cl:go pc-6695))
     pc-6682
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6683)
     pc-6683
       (cl:when flag (cl:setf pc 6688) (cl:go pc-6688))
     pc-6684
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6685)
     pc-6685
       (cl:when flag (cl:setf pc 6693) (cl:go pc-6693))
     pc-6686
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6687)
     pc-6687
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6688
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6689)
     pc-6689
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6690)
     pc-6690
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6691)
     pc-6691
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6692)
     pc-6692
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6693
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6694)
     pc-6694
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6695
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6696)
     pc-6696
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6697
       (cl:push continue stack)
       (cl:setf pc 6698)
     pc-6698
       (cl:push proc stack)
       (cl:setf pc 6699)
     pc-6699
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%create-space| env))
       (cl:setf pc 6700)
     pc-6700
       (cl:push proc stack)
       (cl:setf pc 6701)
     pc-6701
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|symbol->string| env))
       (cl:setf pc 6702)
     pc-6702
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 6703)
     pc-6703
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6704)
     pc-6704
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6705)
     pc-6705
       (cl:when flag (cl:setf pc 6720) (cl:go pc-6720))
     pc-6706
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6707)
     pc-6707
       (cl:when flag (cl:setf pc 6713) (cl:go pc-6713))
     pc-6708
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6709)
     pc-6709
       (cl:when flag (cl:setf pc 6718) (cl:go pc-6718))
     pc-6710
       (cl:setf continue (cl:cons '|compilation-unit| 6721))
       (cl:setf pc 6711)
     pc-6711
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6712)
     pc-6712
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6713
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6714)
     pc-6714
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6715)
     pc-6715
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6716)
     pc-6716
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6717)
     pc-6717
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6718
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6719)
     pc-6719
       (cl:setf pc 6721) (cl:go pc-6721)
     pc-6720
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6721)
     pc-6721
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6722)
     pc-6722
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6723)
     pc-6723
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6724)
     pc-6724
       (cl:when flag (cl:setf pc 6739) (cl:go pc-6739))
     pc-6725
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6726)
     pc-6726
       (cl:when flag (cl:setf pc 6732) (cl:go pc-6732))
     pc-6727
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6728)
     pc-6728
       (cl:when flag (cl:setf pc 6737) (cl:go pc-6737))
     pc-6729
       (cl:setf continue (cl:cons '|compilation-unit| 6740))
       (cl:setf pc 6730)
     pc-6730
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6731)
     pc-6731
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6732
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6733)
     pc-6733
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6734)
     pc-6734
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6735)
     pc-6735
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6736)
     pc-6736
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6737
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6738)
     pc-6738
       (cl:setf pc 6740) (cl:go pc-6740)
     pc-6739
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6740)
     pc-6740
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6741)
     pc-6741
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6742)
     pc-6742
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6743)
     pc-6743
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6744)
     pc-6744
       (cl:when flag (cl:setf pc 6758) (cl:go pc-6758))
     pc-6745
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6746)
     pc-6746
       (cl:when flag (cl:setf pc 6751) (cl:go pc-6751))
     pc-6747
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6748)
     pc-6748
       (cl:when flag (cl:setf pc 6756) (cl:go pc-6756))
     pc-6749
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6750)
     pc-6750
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6751
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6752)
     pc-6752
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6753)
     pc-6753
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6754)
     pc-6754
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6755)
     pc-6755
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6756
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6757)
     pc-6757
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6758
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6759)
     pc-6759
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6760
       (cl:push continue stack)
       (cl:setf pc 6761)
     pc-6761
       (cl:push proc stack)
       (cl:setf pc 6762)
     pc-6762
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|%current-space-id| env))
       (cl:setf pc 6763)
     pc-6763
       (cl:setf argl cl:nil)
       (cl:setf pc 6764)
     pc-6764
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6765)
     pc-6765
       (cl:when flag (cl:setf pc 6780) (cl:go pc-6780))
     pc-6766
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6767)
     pc-6767
       (cl:when flag (cl:setf pc 6773) (cl:go pc-6773))
     pc-6768
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6769)
     pc-6769
       (cl:when flag (cl:setf pc 6778) (cl:go pc-6778))
     pc-6770
       (cl:setf continue (cl:cons '|compilation-unit| 6781))
       (cl:setf pc 6771)
     pc-6771
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6772)
     pc-6772
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6773
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6774)
     pc-6774
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6775)
     pc-6775
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6776)
     pc-6776
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6777)
     pc-6777
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6778
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6779)
     pc-6779
       (cl:setf pc 6781) (cl:go pc-6781)
     pc-6780
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6781)
     pc-6781
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6782)
     pc-6782
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6783)
     pc-6783
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6784)
     pc-6784
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6785)
     pc-6785
       (cl:when flag (cl:setf pc 6799) (cl:go pc-6799))
     pc-6786
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6787)
     pc-6787
       (cl:when flag (cl:setf pc 6792) (cl:go pc-6792))
     pc-6788
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6789)
     pc-6789
       (cl:when flag (cl:setf pc 6797) (cl:go pc-6797))
     pc-6790
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6791)
     pc-6791
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6792
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6793)
     pc-6793
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6794)
     pc-6794
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6795)
     pc-6795
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6796)
     pc-6796
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6797
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6798)
     pc-6798
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6799
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6800)
     pc-6800
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6801
       (cl:push continue stack)
       (cl:setf pc 6802)
     pc-6802
       (cl:push proc stack)
       (cl:setf pc 6803)
     pc-6803
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 6805 env))
       (cl:setf pc 6804)
     pc-6804
       (cl:setf pc 6832) (cl:go pc-6832)
     pc-6805
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 6806)
     pc-6806
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|sm|) argl env 0))
       (cl:setf pc 6807)
     pc-6807
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6808)
     pc-6808
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 6809)
     pc-6809
       (cl:when flag (cl:setf pc 6830) (cl:go pc-6830))
     pc-6810
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 6811)
     pc-6811
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6812)
     pc-6812
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6813)
     pc-6813
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6814)
     pc-6814
       (cl:when flag (cl:setf pc 6828) (cl:go pc-6828))
     pc-6815
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6816)
     pc-6816
       (cl:when flag (cl:setf pc 6821) (cl:go pc-6821))
     pc-6817
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6818)
     pc-6818
       (cl:when flag (cl:setf pc 6826) (cl:go pc-6826))
     pc-6819
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6820)
     pc-6820
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6821
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6822)
     pc-6822
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6823)
     pc-6823
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6824)
     pc-6824
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6825)
     pc-6825
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6826
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6827)
     pc-6827
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6828
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6829)
     pc-6829
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6830
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 6831)
     pc-6831
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6832
       (cl:push proc stack)
       (cl:setf pc 6833)
     pc-6833
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|assoc| env))
       (cl:setf pc 6834)
     pc-6834
       (cl:push proc stack)
       (cl:setf pc 6835)
     pc-6835
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 6836)
     pc-6836
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 6837)
     pc-6837
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6838)
     pc-6838
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6839)
     pc-6839
       (cl:when flag (cl:setf pc 6854) (cl:go pc-6854))
     pc-6840
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6841)
     pc-6841
       (cl:when flag (cl:setf pc 6847) (cl:go pc-6847))
     pc-6842
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6843)
     pc-6843
       (cl:when flag (cl:setf pc 6852) (cl:go pc-6852))
     pc-6844
       (cl:setf continue (cl:cons '|compilation-unit| 6855))
       (cl:setf pc 6845)
     pc-6845
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6846)
     pc-6846
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6847
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6848)
     pc-6848
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6849)
     pc-6849
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6850)
     pc-6850
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6851)
     pc-6851
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6852
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6853)
     pc-6853
       (cl:setf pc 6855) (cl:go pc-6855)
     pc-6854
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6855)
     pc-6855
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6856)
     pc-6856
       (cl:setf val '|source-map|)
       (cl:setf pc 6857)
     pc-6857
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6858)
     pc-6858
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6859)
     pc-6859
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6860)
     pc-6860
       (cl:when flag (cl:setf pc 6875) (cl:go pc-6875))
     pc-6861
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6862)
     pc-6862
       (cl:when flag (cl:setf pc 6868) (cl:go pc-6868))
     pc-6863
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6864)
     pc-6864
       (cl:when flag (cl:setf pc 6873) (cl:go pc-6873))
     pc-6865
       (cl:setf continue (cl:cons '|compilation-unit| 6876))
       (cl:setf pc 6866)
     pc-6866
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6867)
     pc-6867
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6868
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6869)
     pc-6869
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6870)
     pc-6870
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6871)
     pc-6871
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6872)
     pc-6872
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6873
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6874)
     pc-6874
       (cl:setf pc 6876) (cl:go pc-6876)
     pc-6875
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6876)
     pc-6876
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6877)
     pc-6877
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6878)
     pc-6878
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6879)
     pc-6879
       (cl:when flag (cl:setf pc 6894) (cl:go pc-6894))
     pc-6880
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6881)
     pc-6881
       (cl:when flag (cl:setf pc 6887) (cl:go pc-6887))
     pc-6882
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6883)
     pc-6883
       (cl:when flag (cl:setf pc 6892) (cl:go pc-6892))
     pc-6884
       (cl:setf continue (cl:cons '|compilation-unit| 6895))
       (cl:setf pc 6885)
     pc-6885
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6886)
     pc-6886
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6887
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6888)
     pc-6888
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6889)
     pc-6889
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6890)
     pc-6890
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6891)
     pc-6891
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6892
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6893)
     pc-6893
       (cl:setf pc 6895) (cl:go pc-6895)
     pc-6894
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6895)
     pc-6895
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6896)
     pc-6896
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6897)
     pc-6897
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6898)
     pc-6898
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6899)
     pc-6899
       (cl:when flag (cl:setf pc 6913) (cl:go pc-6913))
     pc-6900
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6901)
     pc-6901
       (cl:when flag (cl:setf pc 6906) (cl:go pc-6906))
     pc-6902
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6903)
     pc-6903
       (cl:when flag (cl:setf pc 6911) (cl:go pc-6911))
     pc-6904
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6905)
     pc-6905
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6906
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6907)
     pc-6907
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6908)
     pc-6908
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6909)
     pc-6909
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6910)
     pc-6910
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6911
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6912)
     pc-6912
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6913
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6914)
     pc-6914
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6915
       (cl:push continue stack)
       (cl:setf pc 6916)
     pc-6916
       (cl:push proc stack)
       (cl:setf pc 6917)
     pc-6917
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cadr| env))
       (cl:setf pc 6918)
     pc-6918
       (cl:push proc stack)
       (cl:setf pc 6919)
     pc-6919
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|assoc| env))
       (cl:setf pc 6920)
     pc-6920
       (cl:push proc stack)
       (cl:setf pc 6921)
     pc-6921
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|cdr| env))
       (cl:setf pc 6922)
     pc-6922
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 6923)
     pc-6923
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6924)
     pc-6924
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6925)
     pc-6925
       (cl:when flag (cl:setf pc 6940) (cl:go pc-6940))
     pc-6926
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6927)
     pc-6927
       (cl:when flag (cl:setf pc 6933) (cl:go pc-6933))
     pc-6928
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6929)
     pc-6929
       (cl:when flag (cl:setf pc 6938) (cl:go pc-6938))
     pc-6930
       (cl:setf continue (cl:cons '|compilation-unit| 6941))
       (cl:setf pc 6931)
     pc-6931
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6932)
     pc-6932
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6933
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6934)
     pc-6934
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6935)
     pc-6935
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6936)
     pc-6936
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6937)
     pc-6937
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6938
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6939)
     pc-6939
       (cl:setf pc 6941) (cl:go pc-6941)
     pc-6940
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6941)
     pc-6941
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6942)
     pc-6942
       (cl:setf val '|space|)
       (cl:setf pc 6943)
     pc-6943
       (cl:setf argl (cl:funcall (get-operation '|cons|) val argl))
       (cl:setf pc 6944)
     pc-6944
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6945)
     pc-6945
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6946)
     pc-6946
       (cl:when flag (cl:setf pc 6961) (cl:go pc-6961))
     pc-6947
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6948)
     pc-6948
       (cl:when flag (cl:setf pc 6954) (cl:go pc-6954))
     pc-6949
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6950)
     pc-6950
       (cl:when flag (cl:setf pc 6959) (cl:go pc-6959))
     pc-6951
       (cl:setf continue (cl:cons '|compilation-unit| 6962))
       (cl:setf pc 6952)
     pc-6952
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6953)
     pc-6953
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6954
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6955)
     pc-6955
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6956)
     pc-6956
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6957)
     pc-6957
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6958)
     pc-6958
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6959
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6960)
     pc-6960
       (cl:setf pc 6962) (cl:go pc-6962)
     pc-6961
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6962)
     pc-6962
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6963)
     pc-6963
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6964)
     pc-6964
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6965)
     pc-6965
       (cl:when flag (cl:setf pc 6980) (cl:go pc-6980))
     pc-6966
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6967)
     pc-6967
       (cl:when flag (cl:setf pc 6973) (cl:go pc-6973))
     pc-6968
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6969)
     pc-6969
       (cl:when flag (cl:setf pc 6978) (cl:go pc-6978))
     pc-6970
       (cl:setf continue (cl:cons '|compilation-unit| 6981))
       (cl:setf pc 6971)
     pc-6971
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6972)
     pc-6972
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6973
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6974)
     pc-6974
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6975)
     pc-6975
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6976)
     pc-6976
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6977)
     pc-6977
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6978
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6979)
     pc-6979
       (cl:setf pc 6981) (cl:go pc-6981)
     pc-6980
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 6981)
     pc-6981
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 6982)
     pc-6982
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 6983)
     pc-6983
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 6984)
     pc-6984
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 6985)
     pc-6985
       (cl:when flag (cl:setf pc 6999) (cl:go pc-6999))
     pc-6986
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 6987)
     pc-6987
       (cl:when flag (cl:setf pc 6992) (cl:go pc-6992))
     pc-6988
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 6989)
     pc-6989
       (cl:when flag (cl:setf pc 6997) (cl:go pc-6997))
     pc-6990
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 6991)
     pc-6991
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6992
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 6993)
     pc-6993
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 6994)
     pc-6994
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 6995)
     pc-6995
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 6996)
     pc-6996
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6997
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 6998)
     pc-6998
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-6999
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7000)
     pc-7000
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7001
       (cl:push continue stack)
       (cl:setf pc 7002)
     pc-7002
       (cl:push proc stack)
       (cl:setf pc 7003)
     pc-7003
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|ece-scheme-read| env))
       (cl:setf pc 7004)
     pc-7004
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 7005)
     pc-7005
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7006)
     pc-7006
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7007)
     pc-7007
       (cl:when flag (cl:setf pc 7022) (cl:go pc-7022))
     pc-7008
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7009)
     pc-7009
       (cl:when flag (cl:setf pc 7015) (cl:go pc-7015))
     pc-7010
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7011)
     pc-7011
       (cl:when flag (cl:setf pc 7020) (cl:go pc-7020))
     pc-7012
       (cl:setf continue (cl:cons '|compilation-unit| 7023))
       (cl:setf pc 7013)
     pc-7013
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7014)
     pc-7014
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7015
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7016)
     pc-7016
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7017)
     pc-7017
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7018)
     pc-7018
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7019)
     pc-7019
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7020
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7021)
     pc-7021
       (cl:setf pc 7023) (cl:go pc-7023)
     pc-7022
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7023)
     pc-7023
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7024)
     pc-7024
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 7025)
     pc-7025
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 7026)
     pc-7026
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7027)
     pc-7027
       (cl:when flag (cl:setf pc 7041) (cl:go pc-7041))
     pc-7028
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7029)
     pc-7029
       (cl:when flag (cl:setf pc 7034) (cl:go pc-7034))
     pc-7030
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7031)
     pc-7031
       (cl:when flag (cl:setf pc 7039) (cl:go pc-7039))
     pc-7032
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7033)
     pc-7033
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7034
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7035)
     pc-7035
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7036)
     pc-7036
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7037)
     pc-7037
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7038)
     pc-7038
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7039
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7040)
     pc-7040
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7041
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7042)
     pc-7042
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7043
       (cl:funcall (get-operation '|define-variable!|) '|load-section-from-port| val env)
       (cl:setf pc 7044)
     pc-7044
       (cl:setf val val)
       (cl:setf pc 7045)
     pc-7045
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 7046)
     pc-7046
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 7048 env))
       (cl:setf pc 7047)
     pc-7047
       (cl:setf pc 7169) (cl:go pc-7169)
     pc-7048
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 7049)
     pc-7049
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|filename|) argl env 0))
       (cl:setf pc 7050)
     pc-7050
       (cl:setf val "Load and execute compiled code from a .ecec file (first section only).
For multi-space bundles, only the first section is loaded.")
       (cl:setf pc 7051)
     pc-7051
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 7053 env))
       (cl:setf pc 7052)
     pc-7052
       (cl:setf pc 7127) (cl:go pc-7127)
     pc-7053
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 7054)
     pc-7054
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|port|) argl env 0))
       (cl:setf pc 7055)
     pc-7055
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 7057 env))
       (cl:setf pc 7056)
     pc-7056
       (cl:setf pc 7085) (cl:go pc-7085)
     pc-7057
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 7058)
     pc-7058
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|result|) argl env 0))
       (cl:setf pc 7059)
     pc-7059
       (cl:push continue stack)
       (cl:setf pc 7060)
     pc-7060
       (cl:push env stack)
       (cl:setf pc 7061)
     pc-7061
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|close-input-port| env))
       (cl:setf pc 7062)
     pc-7062
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 7063)
     pc-7063
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7064)
     pc-7064
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7065)
     pc-7065
       (cl:when flag (cl:setf pc 7080) (cl:go pc-7080))
     pc-7066
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7067)
     pc-7067
       (cl:when flag (cl:setf pc 7073) (cl:go pc-7073))
     pc-7068
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7069)
     pc-7069
       (cl:when flag (cl:setf pc 7078) (cl:go pc-7078))
     pc-7070
       (cl:setf continue (cl:cons '|compilation-unit| 7081))
       (cl:setf pc 7071)
     pc-7071
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7072)
     pc-7072
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7073
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7074)
     pc-7074
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7075)
     pc-7075
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7076)
     pc-7076
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7077)
     pc-7077
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7078
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7079)
     pc-7079
       (cl:setf pc 7081) (cl:go pc-7081)
     pc-7080
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7081)
     pc-7081
       (cl:setf env (cl:pop stack))
       (cl:setf pc 7082)
     pc-7082
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 7083)
     pc-7083
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 7084)
     pc-7084
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7085
       (cl:push continue stack)
       (cl:setf pc 7086)
     pc-7086
       (cl:push proc stack)
       (cl:setf pc 7087)
     pc-7087
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|load-section-from-port| env))
       (cl:setf pc 7088)
     pc-7088
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 7089)
     pc-7089
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7090)
     pc-7090
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7091)
     pc-7091
       (cl:when flag (cl:setf pc 7106) (cl:go pc-7106))
     pc-7092
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7093)
     pc-7093
       (cl:when flag (cl:setf pc 7099) (cl:go pc-7099))
     pc-7094
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7095)
     pc-7095
       (cl:when flag (cl:setf pc 7104) (cl:go pc-7104))
     pc-7096
       (cl:setf continue (cl:cons '|compilation-unit| 7107))
       (cl:setf pc 7097)
     pc-7097
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7098)
     pc-7098
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7099
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7100)
     pc-7100
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7101)
     pc-7101
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7102)
     pc-7102
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7103)
     pc-7103
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7104
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7105)
     pc-7105
       (cl:setf pc 7107) (cl:go pc-7107)
     pc-7106
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7107)
     pc-7107
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7108)
     pc-7108
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 7109)
     pc-7109
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 7110)
     pc-7110
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7111)
     pc-7111
       (cl:when flag (cl:setf pc 7125) (cl:go pc-7125))
     pc-7112
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7113)
     pc-7113
       (cl:when flag (cl:setf pc 7118) (cl:go pc-7118))
     pc-7114
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7115)
     pc-7115
       (cl:when flag (cl:setf pc 7123) (cl:go pc-7123))
     pc-7116
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7117)
     pc-7117
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7118
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7119)
     pc-7119
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7120)
     pc-7120
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7121)
     pc-7121
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7122)
     pc-7122
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7123
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7124)
     pc-7124
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7125
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7126)
     pc-7126
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7127
       (cl:push continue stack)
       (cl:setf pc 7128)
     pc-7128
       (cl:push proc stack)
       (cl:setf pc 7129)
     pc-7129
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|open-input-file| env))
       (cl:setf pc 7130)
     pc-7130
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 7131)
     pc-7131
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7132)
     pc-7132
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7133)
     pc-7133
       (cl:when flag (cl:setf pc 7148) (cl:go pc-7148))
     pc-7134
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7135)
     pc-7135
       (cl:when flag (cl:setf pc 7141) (cl:go pc-7141))
     pc-7136
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7137)
     pc-7137
       (cl:when flag (cl:setf pc 7146) (cl:go pc-7146))
     pc-7138
       (cl:setf continue (cl:cons '|compilation-unit| 7149))
       (cl:setf pc 7139)
     pc-7139
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7140)
     pc-7140
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7141
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7142)
     pc-7142
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7143)
     pc-7143
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7144)
     pc-7144
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7145)
     pc-7145
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7146
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7147)
     pc-7147
       (cl:setf pc 7149) (cl:go pc-7149)
     pc-7148
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7149)
     pc-7149
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7150)
     pc-7150
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 7151)
     pc-7151
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 7152)
     pc-7152
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7153)
     pc-7153
       (cl:when flag (cl:setf pc 7167) (cl:go pc-7167))
     pc-7154
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7155)
     pc-7155
       (cl:when flag (cl:setf pc 7160) (cl:go pc-7160))
     pc-7156
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7157)
     pc-7157
       (cl:when flag (cl:setf pc 7165) (cl:go pc-7165))
     pc-7158
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7159)
     pc-7159
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7160
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7161)
     pc-7161
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7162)
     pc-7162
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7163)
     pc-7163
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7164)
     pc-7164
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7165
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7166)
     pc-7166
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7167
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7168)
     pc-7168
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7169
       (cl:funcall (get-operation '|define-variable!|) '|load-compiled| val env)
       (cl:setf pc 7170)
     pc-7170
       (cl:setf val val)
       (cl:setf pc 7171)
     pc-7171
       (cl:setf env (cl:funcall (get-operation '|lookup-variable-value|) '|*global-env*| env))
       (cl:setf pc 7172)
     pc-7172
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 7174 env))
       (cl:setf pc 7173)
     pc-7173
       (cl:setf pc 7418) (cl:go pc-7418)
     pc-7174
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 7175)
     pc-7175
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|filename|) argl env 0))
       (cl:setf pc 7176)
     pc-7176
       (cl:setf val "Load and execute all sections from a .ecec bundle file.
Each section creates a new space, registers its source-map, and executes
sequentially. Definitions from earlier sections are available to later ones.
Returns the result of the last section.")
       (cl:setf pc 7177)
     pc-7177
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 7179 env))
       (cl:setf pc 7178)
     pc-7178
       (cl:setf pc 7376) (cl:go pc-7376)
     pc-7179
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 7180)
     pc-7180
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|port|) argl env 0))
       (cl:setf pc 7181)
     pc-7181
       (cl:push continue stack)
       (cl:setf pc 7182)
     pc-7182
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 7184 env))
       (cl:setf pc 7183)
     pc-7183
       (cl:setf pc 7335) (cl:go pc-7335)
     pc-7184
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 7185)
     pc-7185
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|loop|) argl env 0))
       (cl:setf pc 7186)
     pc-7186
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 7188 env))
       (cl:setf pc 7187)
     pc-7187
       (cl:setf pc 7195) (cl:go pc-7195)
     pc-7188
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 7189)
     pc-7189
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|g185|) argl env 0))
       (cl:setf pc 7190)
     pc-7190
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 7191)
     pc-7191
       (cl:funcall (get-operation '|lexical-set!|) 1 0 val env)
       (cl:setf pc 7192)
     pc-7192
       (cl:setf val val)
       (cl:setf pc 7193)
     pc-7193
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 7194)
     pc-7194
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7195
       (cl:setf val (cl:funcall (get-operation '|make-compiled-procedure|) 7197 env))
       (cl:setf pc 7196)
     pc-7196
       (cl:setf pc 7317) (cl:go pc-7317)
     pc-7197
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 7198)
     pc-7198
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|last-result|) argl env 0))
       (cl:setf pc 7199)
     pc-7199
       (cl:setf proc (cl:funcall (get-operation '|make-compiled-procedure|) 7201 env))
       (cl:setf pc 7200)
     pc-7200
       (cl:setf pc 7275) (cl:go pc-7275)
     pc-7201
       (cl:setf env (cl:funcall (get-operation '|compiled-procedure-env|) proc))
       (cl:setf pc 7202)
     pc-7202
       (cl:setf env (cl:funcall (get-operation '|extend-environment|) '(|result|) argl env 0))
       (cl:setf pc 7203)
     pc-7203
       (cl:push continue stack)
       (cl:setf pc 7204)
     pc-7204
       (cl:push env stack)
       (cl:setf pc 7205)
     pc-7205
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|eof?| env))
       (cl:setf pc 7206)
     pc-7206
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 7207)
     pc-7207
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7208)
     pc-7208
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7209)
     pc-7209
       (cl:when flag (cl:setf pc 7224) (cl:go pc-7224))
     pc-7210
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7211)
     pc-7211
       (cl:when flag (cl:setf pc 7217) (cl:go pc-7217))
     pc-7212
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7213)
     pc-7213
       (cl:when flag (cl:setf pc 7222) (cl:go pc-7222))
     pc-7214
       (cl:setf continue (cl:cons '|compilation-unit| 7225))
       (cl:setf pc 7215)
     pc-7215
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7216)
     pc-7216
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7217
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7218)
     pc-7218
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7219)
     pc-7219
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7220)
     pc-7220
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7221)
     pc-7221
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7222
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7223)
     pc-7223
       (cl:setf pc 7225) (cl:go pc-7225)
     pc-7224
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7225)
     pc-7225
       (cl:setf env (cl:pop stack))
       (cl:setf pc 7226)
     pc-7226
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 7227)
     pc-7227
       (cl:setf flag (cl:funcall (get-operation '|false?|) val))
       (cl:setf pc 7228)
     pc-7228
       (cl:when flag (cl:setf pc 7255) (cl:go pc-7255))
     pc-7229
       (cl:push continue stack)
       (cl:setf pc 7230)
     pc-7230
       (cl:push env stack)
       (cl:setf pc 7231)
     pc-7231
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|close-input-port| env))
       (cl:setf pc 7232)
     pc-7232
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 3 0 env))
       (cl:setf pc 7233)
     pc-7233
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7234)
     pc-7234
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7235)
     pc-7235
       (cl:when flag (cl:setf pc 7250) (cl:go pc-7250))
     pc-7236
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7237)
     pc-7237
       (cl:when flag (cl:setf pc 7243) (cl:go pc-7243))
     pc-7238
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7239)
     pc-7239
       (cl:when flag (cl:setf pc 7248) (cl:go pc-7248))
     pc-7240
       (cl:setf continue (cl:cons '|compilation-unit| 7251))
       (cl:setf pc 7241)
     pc-7241
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7242)
     pc-7242
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7243
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7244)
     pc-7244
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7245)
     pc-7245
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7246)
     pc-7246
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7247)
     pc-7247
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7248
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7249)
     pc-7249
       (cl:setf pc 7251) (cl:go pc-7251)
     pc-7250
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7251)
     pc-7251
       (cl:setf env (cl:pop stack))
       (cl:setf pc 7252)
     pc-7252
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 7253)
     pc-7253
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 1 0 env))
       (cl:setf pc 7254)
     pc-7254
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7255
       (cl:setf proc (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 7256)
     pc-7256
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 7257)
     pc-7257
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7258)
     pc-7258
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7259)
     pc-7259
       (cl:when flag (cl:setf pc 7273) (cl:go pc-7273))
     pc-7260
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7261)
     pc-7261
       (cl:when flag (cl:setf pc 7266) (cl:go pc-7266))
     pc-7262
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7263)
     pc-7263
       (cl:when flag (cl:setf pc 7271) (cl:go pc-7271))
     pc-7264
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7265)
     pc-7265
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7266
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7267)
     pc-7267
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7268)
     pc-7268
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7269)
     pc-7269
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7270)
     pc-7270
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7271
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7272)
     pc-7272
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7273
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7274)
     pc-7274
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7275
       (cl:push continue stack)
       (cl:setf pc 7276)
     pc-7276
       (cl:push proc stack)
       (cl:setf pc 7277)
     pc-7277
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|load-section-from-port| env))
       (cl:setf pc 7278)
     pc-7278
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 2 0 env))
       (cl:setf pc 7279)
     pc-7279
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7280)
     pc-7280
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7281)
     pc-7281
       (cl:when flag (cl:setf pc 7296) (cl:go pc-7296))
     pc-7282
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7283)
     pc-7283
       (cl:when flag (cl:setf pc 7289) (cl:go pc-7289))
     pc-7284
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7285)
     pc-7285
       (cl:when flag (cl:setf pc 7294) (cl:go pc-7294))
     pc-7286
       (cl:setf continue (cl:cons '|compilation-unit| 7297))
       (cl:setf pc 7287)
     pc-7287
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7288)
     pc-7288
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7289
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7290)
     pc-7290
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7291)
     pc-7291
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7292)
     pc-7292
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7293)
     pc-7293
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7294
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7295)
     pc-7295
       (cl:setf pc 7297) (cl:go pc-7297)
     pc-7296
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7297)
     pc-7297
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7298)
     pc-7298
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 7299)
     pc-7299
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 7300)
     pc-7300
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7301)
     pc-7301
       (cl:when flag (cl:setf pc 7315) (cl:go pc-7315))
     pc-7302
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7303)
     pc-7303
       (cl:when flag (cl:setf pc 7308) (cl:go pc-7308))
     pc-7304
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7305)
     pc-7305
       (cl:when flag (cl:setf pc 7313) (cl:go pc-7313))
     pc-7306
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7307)
     pc-7307
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7308
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7309)
     pc-7309
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7310)
     pc-7310
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7311)
     pc-7311
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7312)
     pc-7312
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7313
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7314)
     pc-7314
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7315
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7316)
     pc-7316
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7317
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7318)
     pc-7318
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7319)
     pc-7319
       (cl:when flag (cl:setf pc 7333) (cl:go pc-7333))
     pc-7320
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7321)
     pc-7321
       (cl:when flag (cl:setf pc 7326) (cl:go pc-7326))
     pc-7322
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7323)
     pc-7323
       (cl:when flag (cl:setf pc 7331) (cl:go pc-7331))
     pc-7324
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7325)
     pc-7325
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7326
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7327)
     pc-7327
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7328)
     pc-7328
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7329)
     pc-7329
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7330)
     pc-7330
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7331
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7332)
     pc-7332
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7333
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7334)
     pc-7334
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7335
       (cl:setf val cl:nil)
       (cl:setf pc 7336)
     pc-7336
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7337)
     pc-7337
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7338)
     pc-7338
       (cl:when flag (cl:setf pc 7355) (cl:go pc-7355))
     pc-7339
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7340)
     pc-7340
       (cl:when flag (cl:setf pc 7348) (cl:go pc-7348))
     pc-7341
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7342)
     pc-7342
       (cl:when flag (cl:setf pc 7353) (cl:go pc-7353))
     pc-7343
       (cl:setf continue (cl:cons '|compilation-unit| 7346))
       (cl:setf pc 7344)
     pc-7344
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7345)
     pc-7345
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7346
       (cl:setf proc val)
       (cl:setf pc 7347)
     pc-7347
       (cl:setf pc 7356) (cl:go pc-7356)
     pc-7348
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7349)
     pc-7349
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7350)
     pc-7350
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7351)
     pc-7351
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7352)
     pc-7352
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7353
       (cl:setf proc (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7354)
     pc-7354
       (cl:setf pc 7356) (cl:go pc-7356)
     pc-7355
       (cl:setf proc (cl:funcall (get-operation '|apply-primitive-procedure|) proc argl))
       (cl:setf pc 7356)
     pc-7356
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 7357)
     pc-7357
       (cl:setf val ece::*scheme-false*)
       (cl:setf pc 7358)
     pc-7358
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7359)
     pc-7359
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7360)
     pc-7360
       (cl:when flag (cl:setf pc 7374) (cl:go pc-7374))
     pc-7361
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7362)
     pc-7362
       (cl:when flag (cl:setf pc 7367) (cl:go pc-7367))
     pc-7363
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7364)
     pc-7364
       (cl:when flag (cl:setf pc 7372) (cl:go pc-7372))
     pc-7365
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7366)
     pc-7366
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7367
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7368)
     pc-7368
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7369)
     pc-7369
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7370)
     pc-7370
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7371)
     pc-7371
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7372
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7373)
     pc-7373
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7374
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7375)
     pc-7375
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7376
       (cl:push continue stack)
       (cl:setf pc 7377)
     pc-7377
       (cl:push proc stack)
       (cl:setf pc 7378)
     pc-7378
       (cl:setf proc (cl:funcall (get-operation '|lookup-variable-value|) '|open-input-file| env))
       (cl:setf pc 7379)
     pc-7379
       (cl:setf val (cl:funcall (get-operation '|lexical-ref|) 0 0 env))
       (cl:setf pc 7380)
     pc-7380
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7381)
     pc-7381
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7382)
     pc-7382
       (cl:when flag (cl:setf pc 7397) (cl:go pc-7397))
     pc-7383
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7384)
     pc-7384
       (cl:when flag (cl:setf pc 7390) (cl:go pc-7390))
     pc-7385
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7386)
     pc-7386
       (cl:when flag (cl:setf pc 7395) (cl:go pc-7395))
     pc-7387
       (cl:setf continue (cl:cons '|compilation-unit| 7398))
       (cl:setf pc 7388)
     pc-7388
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7389)
     pc-7389
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7390
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7391)
     pc-7391
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7392)
     pc-7392
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7393)
     pc-7393
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7394)
     pc-7394
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7395
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7396)
     pc-7396
       (cl:setf pc 7398) (cl:go pc-7398)
     pc-7397
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7398)
     pc-7398
       (cl:setf argl (cl:funcall (get-operation '|list|) val))
       (cl:setf pc 7399)
     pc-7399
       (cl:setf proc (cl:pop stack))
       (cl:setf pc 7400)
     pc-7400
       (cl:setf continue (cl:pop stack))
       (cl:setf pc 7401)
     pc-7401
       (cl:setf flag (cl:funcall (get-operation '|primitive-procedure?|) proc))
       (cl:setf pc 7402)
     pc-7402
       (cl:when flag (cl:setf pc 7416) (cl:go pc-7416))
     pc-7403
       (cl:setf flag (cl:funcall (get-operation '|continuation?|) proc))
       (cl:setf pc 7404)
     pc-7404
       (cl:when flag (cl:setf pc 7409) (cl:go pc-7409))
     pc-7405
       (cl:setf flag (cl:funcall (get-operation '|parameter?|) proc))
       (cl:setf pc 7406)
     pc-7406
       (cl:when flag (cl:setf pc 7414) (cl:go pc-7414))
     pc-7407
       (cl:setf val (cl:funcall (get-operation '|compiled-procedure-entry|) proc))
       (cl:setf pc 7408)
     pc-7408
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7409
       (cl:setf val (cl:funcall (get-operation '|car|) argl))
       (cl:setf pc 7410)
     pc-7410
       (cl:funcall (get-operation '|do-continuation-winds|) proc)
       (cl:setf pc 7411)
     pc-7411
       (cl:setf stack (cl:funcall (get-operation '|continuation-stack|) proc))
       (cl:setf pc 7412)
     pc-7412
       (cl:setf continue (cl:funcall (get-operation '|continuation-conts|) proc))
       (cl:setf pc 7413)
     pc-7413
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7414
       (cl:setf val (cl:funcall (get-operation '|apply-parameter|) proc argl))
       (cl:setf pc 7415)
     pc-7415
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7416
       (cl:setf val (apply-primitive-procedure proc argl))
       (cl:setf pc 7417)
     pc-7417
       (cl:setf bail cl:t) (cl:go chunk-exit)
     pc-7418
       (cl:funcall (get-operation '|define-variable!|) '|load-bundle| val env)
       (cl:setf pc 7419)
     pc-7419
       (cl:setf val val)
       (cl:setf pc 7420)
     chunk-exit)
    (cl:values pc val env proc argl continue stack bail)))

(defun zone-compilation-unit (initial-pc initial-val initial-env initial-proc initial-argl initial-continue initial-stack)
  (cl:let ((pc initial-pc)
           (val initial-val)
           (env initial-env)
           (proc initial-proc)
           (argl initial-argl)
           (continue initial-continue)
           (stack initial-stack)
           (bail cl:nil))
    (cl:loop
      (cl:when (cl:or (cl:>= pc 7420) (cl:< pc 0))
        (cl:return (cl:values pc val env proc argl continue stack)))
      (cl:cond
        ((cl:< pc 4096)
         (cl:multiple-value-setq (pc val env proc argl continue stack bail)
           (zone-compilation-unit-chunk-0 pc val env proc argl continue stack)))
        ((cl:< pc 7420)
         (cl:multiple-value-setq (pc val env proc argl continue stack bail)
           (zone-compilation-unit-chunk-1 pc val env proc argl continue stack)))
        (cl:t (cl:return (cl:values pc val env proc argl continue stack))))
      (cl:when bail
        (cl:return (cl:values pc val env proc argl continue stack))))))

;;; Self-registration: install zone-compilation-unit under the space symbol so
;;; execute-instructions dispatches to it on entry to this space.
(cl:setf (cl:gethash '|compilation-unit| *compiled-zone-functions*)
         (cl:function zone-compilation-unit))
