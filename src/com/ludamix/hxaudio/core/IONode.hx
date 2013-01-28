package com.ludamix.hxaudio.core;

class IOConnection<T>
{
	
	public var slot_send : Int;
	public var slot_recieve : Int;
	public var send : IONode<T>; 
	public var recieve : IONode<T>;
	
	public function new(send, recieve, slot_send, slot_recieve)
	{
		this.send = send;
		this.recieve = recieve;
		this.slot_send = slot_send;
		this.slot_recieve = slot_recieve;
	}
	
	public function connect()
	{
		disconnect();
		this.send.outputs.push(this);
		this.recieve.inputs.push(this);
	}
	
	public function equals(a :IOConnection<T>)
	{
		return 	a.slot_send == this.slot_send &&
				a.slot_recieve == this.slot_recieve &&
				a.send == this.send && 
				a.recieve == this.recieve;
	}
	
	public function disconnect()
	{
		this.send.outputs = Lambda.filter(this.send.outputs, equals);
		this.recieve.inputs = Lambda.filter(this.recieve.inputs, equals);
	}
	
}

class IONode<T>
{

	public var inputs : Array<IOConnection<T>>;
	public var outputs : Array<IOConnection<T>>;
	public var search_flip : Bool;
	
	public function new()
	{
	
	}
	
	public inline function getInputs(slot : Int)
	{
		return Lambda.filter(inputs, function (a : IOConnection<T>) { return a.slot_send == slot; } );
	}
	
	public inline function getOutputs(slot : Int)
	{
		return Lambda.filter(outputs, function (a : IOConnection<T>) { return a.slot_recieve == slot; } );
	}
	
	public inline function connect(destination, slot_send, slot_recieve)
	{
		var cnx = new IOConnection(this, destination, slot_send, slot_recieve);
		cnx.connect();
		destination.search_flip = this.search_flip;
	}
	
	public inline function disconnectOutputs()
	{
		for ( o in outputs ) o.disconnect();
	}
	
	public inline function disconnectInputs()
	{
		for ( i in inputs ) i.disconnect();
	}
	
	/**
	 * Greedy search for a node of a specific type according to a comparison function.
	 * @param	compare Comparison function. True adds the node to the return result.
	 * @param	?inputs=true Check the inputs of each node.
	 * @param	?outputs=true Check the outputs of each node.
	 * @return
	 */
	public function findNodes(compare : IONode<T>->Bool, ?inputs=true, ?outputs=true) : Array<IONode>
	{
		var open = new Array<IONode>();
		var result = new Array<IONode>();
		
		open.push(this);
		var flip = !this.search_flip;
		
		while (open.length > 0)
		{
			var cur = open.shift();
			cur.search_flip = flip;
			if (compare(cur))
				result.push(cur);
			if (inputs)
			{
				for (n in cur.inputs)
				{
					if (n.search_flip != flip)
						open.push(n);
				}
			}
			if (outputs)
			{
				for (n in cur.outputs)
				{
					if (n.search_flip != flip)
						open.push(n);				
				}
			}
		}
		return result;
		
	}
	
}