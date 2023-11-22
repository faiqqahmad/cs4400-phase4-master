import React from "react";
import Link from "next/link";
import styles from "@/styles/Navbar.module.css";

const Navbar = (props) => (
	<header className={styles.nav}>
		<div className={styles.navLogo}>
			<h1>CS 4400 Phase 4</h1>
		</div>
		<nav className={styles.navItems}>
			<ul>
				<li>
					<Link href="/tables">Tables</Link>
				</li>
				<li>
					<Link href="/procedures">Procedures</Link>
				</li>
				<li>
					<Link href="/views">View</Link>
				</li>
				<li>
					<Link href="/misc">Misc</Link>
				</li>
			</ul>
		</nav>
	</header>
);

export default Navbar;
