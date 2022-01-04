import React, { useContext, useState } from "react";
//import { useState, useEffect } from 'react';
import { makeStyles } from '@material-ui/core/styles';
import ElementRenderer from "./ElementRenderer";
import Typography from '@material-ui/core/Typography';
import Divider from '@material-ui/core/Divider';
import { Button } from '@material-ui/core';
import EditIcon from '@material-ui/icons/Edit';
import AddIcon from "@material-ui/icons/AddBox";
import { DragDropContext, Droppable, Draggable } from "react-beautiful-dnd";
import { FormContext } from '../FormContext';
import DragHandleIcon from "@material-ui/icons/DragIndicator";
import RevertIvon from "@material-ui/icons/History";
import AddElement from "./AddElement";
import EditSchemaHeader from "./EditSchemaHeader";

const useStyles = makeStyles((theme) => ({
    root: {
        width: '100%',
    },
    heading: {
        color: 'rgba(82, 94, 103, 1)',
        fontSize: theme.typography.pxToRem(25),
        fontWeight: theme.typography.fontWeightRegular,
    },
}));

const FormRenderer = ({ revertAllChanges, schema, edit }) => {
    const { updateParent, convertedSchema } = useContext(FormContext);
    const [openDialogAddElement, setOpenDialogAddElement] = useState(false);
    const [openDialog, setOpenDialog] = useState(false);

    const classes = useStyles();

    // deconstruct
    const { properties, title, description, required, $schema, id } = schema ?? {}

    // update the order in properties on drag end
    const handleOnDragEnd = (result) => {
        if (!result.destination) return;
        const items = Array.from(properties);
        const [reorderedItem] = items.splice(result.source.index, 1);
        items.splice(result.destination.index, 0, reorderedItem);

        let value = { ...convertedSchema };
        value["properties"] = items;
        updateParent(value);
    }

    /*
    console.log("converted:", convertedSchema)
    let deconvertedSchema = JSON.parse(JSON.stringify(convertedSchema))
    deconvertedSchema["properties"] = array2object(convertedSchema["properties"])
    console.log("deconverted:", deconvertedSchema)
    */

    // default schema for add new element
    let defaultSchema = {}

    return (<>
        <div style={{ width: "100%", paddingLeft: "10px", paddingRight: "10px" }}>
            <div style={{ paddingTop: "10px", paddingBottom: "10px", display: 'inline-flex', width: '100%' }}>
                <Typography className={classes.heading} style={{ width: "100%" }}>{title}</Typography>
                {edit ? <> <Button onClick={() => setOpenDialog(true)} style={{ marginLeft: "5px" }}> <EditIcon color="primary" /></Button> <Button onClick={() => revertAllChanges()} style={{ marginLeft: "5px" }}> <RevertIvon color="primary" /></Button>  </> : null}
            </div>
            <Divider />
            <Typography>{description}</Typography>
            <DragDropContext onDragEnd={handleOnDragEnd}>
                <Droppable droppableId="forms">
                    {(provided) => (
                        <form {...provided.droppableProps} ref={provided.innerRef}>
                            {Object.keys(properties).map((item, index) => {
                                return (
                                    <Draggable isDragDisabled={!edit} key={properties[item]["fieldId"]} draggableId={properties[item]["fieldId"]} index={index}>
                                        {(provided) => (
                                            <div {...provided.draggableProps} ref={provided.innerRef}>
                                                <div style={{ display: "flex" }}>
                                                    {edit ? <div style={{ width: "20px", marginTop: "10px", height: "30px" }} {...provided.dragHandleProps}>
                                                        <DragHandleIcon fontSize="small" />
                                                    </div> : null}
                                                    <ElementRenderer schema={schema} path={"properties"} fieldId={properties[item]["fieldId"]} fieldIndex={item} elementRequired={required} edit={edit} field={properties[item]} />
                                                </div>
                                            </div>
                                        )}
                                    </Draggable>
                                );
                            })}
                            {provided.placeholder}
                            {edit ? <div style={{ display: "flex", justifyContent: "right" }}>
                                <Button onClick={() => setOpenDialogAddElement(true)} style={{ marginLeft: "5px" }}><AddIcon color="primary" /> ADD ELEMENT</Button>
                            </div> : null}
                        </form>
                    )}
                </Droppable>
            </DragDropContext>
        </div>
        {openDialogAddElement ? <AddElement openDialog={openDialogAddElement} setOpenDialog={setOpenDialogAddElement} defaultSchema={defaultSchema} schemaTitle={title} /> : null}
        {openDialog ? <EditSchemaHeader schemaID={id} title={title} description={description} schemaURI={$schema} openDialog={openDialog} setOpenDialog={setOpenDialog} /> : null}
    </>);
};

export default FormRenderer;