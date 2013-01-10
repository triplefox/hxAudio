package com.ludamix.hxaudio.core;

/*
 * An IntHash that contains an array in each slot, with specialized methods to work with the arrays.
 * */
class IntHashArray<T>
{
	
	public var c : IntHash<Array<T>>;

	public function new()
	{
		c = new IntHash();
	}

	/*
	 * Push v to slot i.
	 * */
	public function push(i, v)
	{
		var table;
		if (c.exists(i)) table = c.get(i);
		else table = new Array<T>();
		
		table.push(v);
	}
	
	/*
	 * Insert v to slot i at position p.
	 * */
	public function insert(i, v, p)
	{
		var table;
		if (c.exists(i)) table = c.get(i);
		else table = new Array<T>();
		
		table.insert(v, p);
	}
	
	/*
	 * Push variable v to slot i, so long as comparison cmp doesn't return true on contents of i against v.
	 * */
	public function pushUnique(i : Int, v : T, ?cmp : T->T->Bool)
	{
		var table;
		if (c.exists(i)) table = c.get(i);
		else table = new Array<T>();
		
		if (cmp == null)
		{
			for (t in table) if (t == v) return;
		}
		else
		{
			for (t in table) if (cmp(v, t)) return;
		}
		
		table.push(v);
	}
	
	/*
	 * Remove and return v from slot i, if it matches(using Array.remove rules)
	 * */
	public function remove(i, v)
	{
		var table;
		if (c.exists(i)) table = c.get(i);
		else { table = new Array<T>(); c.set(i, table); }
		
		return table.remove(v);
	}
	
	/*
	 * Remove and return an array of elements that match cmp.
	 * */
	public function removeKind(i : Int, cmp : T->Bool) : Array<T>
	{
		var table;
		if (c.exists(i)) table = c.get(i);
		else { table = new Array<T>(); }
		
		// rebuild the table
		
		var result : Array<T> = new Array<T>();;
		var repop = new Array<T>();
		for (t in table) if (!cmp(t)) repop.push(t); else result.push(t);
		
		c.set(i, repop);
		
		return result;
	}	
	
	/*
	 * Test whether the slot exists.
	 * */
	public function exists(i : Int)
	{
		return c.exists(i);
	}

	/*
	 * Return the values in slot i that match cmp.
	 * */
	public function getValues(i : Int, cmp : T->Bool)
	{
		var table;
		if (c.exists(i)) table = c.get(i);
		else { table = new Array<T>(); }
		
		var result : Array<T> = new Array<T>();;
		for (t in table) if (cmp(t)) result.push(t);
		return result;
	}
	
}
