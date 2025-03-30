# Lensless_Recover
基于空间光调制器无透镜成像相位恢复/Lensless Imaging Recover by SLM

本项目是 Adaptive lensless microscopic imaging with unknown phase modulation 的代码和部分数据，发表在Biomedical Optics Express上，https://opg.optica.org/boe/fulltext.cfm?uri=boe-16-3-1160&id=568454

Abstract: Lensless imaging is a popular research field for the advantages of small size, wide field-of-view and low aberration in recent years. However, some traditional lensless imaging methods suffer from slow convergence, mechanical errors and conjugate solution interference, which limit its further application and development. In this work, we proposed a lensless imaging method based on spatial light modulator (SLM) with unknown phase modulation values. In our imaging system, the SLM is utilized to modulate the wavefront of the object. When the phase modulation values of the SLM are inaccurate or unknown, conventional algorithms such as amplitude-phase retrieval (APR) or the extended ptychographic iterative engine (ePIE) fail to reconstruct the complex amplitude information of the object. To address this challenge, we introduce a novel approach that combines ptychographic scanning along a spiral path with the ePIE algorithm, enabling accurate reconstruction of the original image. We further analyze the effect of modulation function and the characteristics of the coherent light source on the quality of reconstructed image. The experiments show that the proposed method is superior to traditional methods in terms of recovering speed and accuracy, with the recovering resolution up to 14 $\mu m$ in the reconstruction of USAF phase plate image.

运行AS_recover.m文件,恢复样品的强度和相位信息，releases中data.zip包含USAF板衍射后图像数据

by HITsz ,School of Computer Science and Technology 光学成像组 请勿用于商业用途
代码仅供参考，如若使用到我们的代码，请引用我们的论文，谢谢
